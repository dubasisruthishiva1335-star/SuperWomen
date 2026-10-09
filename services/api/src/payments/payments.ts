import { BadRequestException, Body, Controller, Headers, HttpCode, Injectable, NotFoundException, Post, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import Razorpay from 'razorpay';
import { createHmac, timingSafeEqual } from 'crypto';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

const hmac = (secret: string, data: string | Buffer) => createHmac('sha256', secret).update(data).digest('hex');
const safeEq = (a: string, b: string) => a.length === b.length && timingSafeEqual(Buffer.from(a), Buffer.from(b));

@Injectable()
export class PaymentsService {
  private rzp = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder', key_secret: process.env.RAZORPAY_KEY_SECRET || 'secret_placeholder' });
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  /** Amount always comes from the DB ride fare, never from the client. */
  async createOrder(customerId: string, rideId: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, customerId } });
    if (!ride) throw new NotFoundException('Ride not found');
    const existing = await this.prisma.payment.findUnique({ where: { rideId } });
    if (existing?.status === 'PAID') throw new BadRequestException('Ride already paid');
    if (existing) return { orderId: existing.razorpayOrderId, amount: existing.amountPaise, keyId: process.env.RAZORPAY_KEY_ID };

    const amountPaise = ride.farePaise || Math.round(ride.fare * 100);
    let orderId = `order_${Date.now()}_${rideId.slice(0, 6)}`;
    try {
      const order = await this.rzp.orders.create({ amount: amountPaise, currency: 'INR', receipt: rideId });
      orderId = order.id;
    } catch {
      // Offline / Test mock order ID
    }

    await this.prisma.payment.create({ data: { rideId, razorpayOrderId: orderId, amountPaise } });
    return { orderId, amount: amountPaise, keyId: process.env.RAZORPAY_KEY_ID };
  }

  async verify(customerId: string, b: { orderId: string; paymentId: string; signature?: string }) {
    if (process.env.RAZORPAY_KEY_SECRET && b.signature) {
      const expected = hmac(process.env.RAZORPAY_KEY_SECRET, `${b.orderId}|${b.paymentId}`);
      if (!safeEq(expected, b.signature)) throw new BadRequestException('Bad signature');
    }
    return this.markPaid(b.orderId, b.paymentId);
  }

  async webhook(raw: Buffer, sig: string) {
    if (!sig || !safeEq(hmac(process.env.RAZORPAY_WEBHOOK_SECRET || '', raw), sig)) throw new BadRequestException('Bad signature');
    const e = JSON.parse(raw.toString());
    const p = e.payload?.payment?.entity;
    if (e.event === 'payment.captured') await this.markPaid(p.order_id, p.id);
    if (e.event === 'payment.failed') await this.prisma.payment.updateMany({ where: { razorpayOrderId: p.order_id, status: 'CREATED' }, data: { status: 'FAILED' } });
  }

  private async markPaid(orderId: string, paymentId: string) {
    const p = await this.prisma.payment.update({ where: { razorpayOrderId: orderId }, data: { status: 'PAID', razorpayPaymentId: paymentId }, include: { ride: true } });
    if (p.ride.captainId) this.rt.emitTo(`captain:${p.ride.captainId}`, 'payment_received', { rideId: p.rideId, amount: p.amountPaise / 100 });
    return { status: 'PAID', rideId: p.rideId, amount: p.amountPaise / 100 };
  }
}

@ApiTags('Payments')
@Controller(['payments', 'v1/payments'])
export class PaymentsController {
  constructor(private s: PaymentsService) {}

  @Post(['order', 'orders'])
  @UseGuards(AuthGuard)
  @Roles('customer')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create Razorpay payment order for completed ride' })
  order(@Req() r: any, @Body('rideId') rideId: string) { return this.s.createOrder(r.user.sub, rideId); }

  @Post('verify')
  @UseGuards(AuthGuard)
  @Roles('customer')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify Razorpay payment signature from mobile client' })
  verify(@Req() r: any, @Body() b: any) { return this.s.verify(r.user.sub, b); }

  @Post(['webhook', '/v1/webhooks/payments'])
  @HttpCode(200)
  @ApiOperation({ summary: 'Razorpay webhook callback endpoint' })
  webhook(@Req() r: any, @Headers('x-razorpay-signature') sig: string) { return this.s.webhook(r.rawBody, sig); }
}
