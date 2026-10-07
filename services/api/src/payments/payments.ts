import { BadRequestException, Body, Controller, Headers, HttpCode, Injectable, NotFoundException, Post, Req, UseGuards } from '@nestjs/common';
import Razorpay from 'razorpay';
import { createHmac, timingSafeEqual } from 'crypto';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

const hmac = (secret: string, data: string | Buffer) => createHmac('sha256', secret).update(data).digest('hex');
const safeEq = (a: string, b: string) => a.length === b.length && timingSafeEqual(Buffer.from(a), Buffer.from(b));

@Injectable()
export class PaymentsService {
  private rzp = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID!, key_secret: process.env.RAZORPAY_KEY_SECRET! });
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  /** Amount always comes from the DB ride fare, never from the client. */
  async createOrder(customerId: string, rideId: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, customerId, status: 'COMPLETED' } });
    if (!ride) throw new NotFoundException('Completed ride not found');
    const existing = await this.prisma.payment.findUnique({ where: { rideId } });
    if (existing?.status === 'PAID') throw new BadRequestException('Already paid');
    if (existing) return { orderId: existing.razorpayOrderId, amount: existing.amountPaise, keyId: process.env.RAZORPAY_KEY_ID };

    const amountPaise = Math.round(ride.fare * 100);
    const order = await this.rzp.orders.create({ amount: amountPaise, currency: 'INR', receipt: rideId });
    await this.prisma.payment.create({ data: { rideId, razorpayOrderId: order.id, amountPaise } });
    return { orderId: order.id, amount: amountPaise, keyId: process.env.RAZORPAY_KEY_ID };
  }

  async verify(customerId: string, b: { orderId: string; paymentId: string; signature: string }) {
    const expected = hmac(process.env.RAZORPAY_KEY_SECRET!, `${b.orderId}|${b.paymentId}`);
    if (!safeEq(expected, b.signature)) throw new BadRequestException('Bad signature');
    return this.markPaid(b.orderId, b.paymentId);
  }

  async webhook(raw: Buffer, sig: string) {
    if (!sig || !safeEq(hmac(process.env.RAZORPAY_WEBHOOK_SECRET!, raw), sig)) throw new BadRequestException('Bad signature');
    const e = JSON.parse(raw.toString());
    const p = e.payload?.payment?.entity;
    if (e.event === 'payment.captured') await this.markPaid(p.order_id, p.id);
    if (e.event === 'payment.failed') await this.prisma.payment.updateMany({ where: { razorpayOrderId: p.order_id, status: 'CREATED' }, data: { status: 'FAILED' } });
  }

  private async markPaid(orderId: string, paymentId: string) {
    const p = await this.prisma.payment.update({ where: { razorpayOrderId: orderId }, data: { status: 'PAID', razorpayPaymentId: paymentId }, include: { ride: true } });
    if (p.ride.captainId) this.rt.emitTo(`captain:${p.ride.captainId}`, 'payment_received', { rideId: p.rideId, amount: p.amountPaise / 100 });
    return { status: 'PAID' };
  }
}

@Controller('payments')
export class PaymentsController {
  constructor(private s: PaymentsService) {}
  @Post('order') @UseGuards(AuthGuard) @Roles('customer')
  order(@Req() r: any, @Body('rideId') rideId: string) { return this.s.createOrder(r.user.sub, rideId); }

  @Post('verify') @UseGuards(AuthGuard) @Roles('customer')
  verify(@Req() r: any, @Body() b: any) { return this.s.verify(r.user.sub, b); }

  @Post('webhook') @HttpCode(200)
  webhook(@Req() r: any, @Headers('x-razorpay-signature') sig: string) { return this.s.webhook(r.rawBody, sig); }
}
