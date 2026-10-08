import { BadRequestException, Body, ConflictException, Controller, Injectable, Param, Post, Req, UseGuards } from '@nestjs/common';
import { randomInt } from 'crypto';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService, RedisService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

const km = (aLat: number, aLng: number, bLat: number, bLng: number) => {
  const R = 6371, r = (d: number) => (d * Math.PI) / 180;
  const x = Math.sin(r(bLat - aLat) / 2) ** 2 + Math.cos(r(aLat)) * Math.cos(r(bLat)) * Math.sin(r(bLng - aLng) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(x));
};

@Injectable()
export class RidesService {
  constructor(private prisma: PrismaService, private redis: RedisService, private rt: RealtimeGateway) {}

  fare(d: any) { return Math.max(50, Math.round(30 + 12 * km(d.pickupLat, d.pickupLng, d.dropLat, d.dropLng))); } // server-side only

  async request(customerId: string, d: any) {
    const ride = await this.prisma.ride.create({ data: {
      customerId, pickupLat: d.pickupLat, pickupLng: d.pickupLng, dropLat: d.dropLat, dropLng: d.dropLng,
      fare: this.fare(d), otp: String(randomInt(1000, 10000)),
    } });
    const { otp, ...publicRide } = ride; // never send OTP to captains
    let dispatched = false;
    try {
      const near = (await this.redis.georadius('captains:online', d.pickupLng, d.pickupLat, 10, 'km', 'ASC')) as string[];
      for (const id of near) {
        if (await this.redis.exists(`captain:alive:${id}`)) {
          this.rt.emitTo(`captain:${id}`, 'ride_request', publicRide);
          dispatched = true;
        }
      }
    } catch {}

    if (!dispatched) {
      const onlineCaptains = await this.prisma.captain.findMany({ where: { isOnline: true } });
      for (const cap of onlineCaptains) {
        this.rt.emitTo(`captain:${cap.id}`, 'ride_request', publicRide);
      }
    }
    this.rt.emitTo('captains:all', 'ride_request', publicRide);
    return ride;
  }

  async accept(rideId: string, captainId: string) {
    const r = await this.prisma.ride.updateMany({ where: { id: rideId, status: 'SEARCHING', captainId: null }, data: { captainId, status: 'ACCEPTED' } });
    if (!r.count) throw new ConflictException('Ride already taken');
    const ride = await this.prisma.ride.findUnique({ where: { id: rideId }, include: { captain: { include: { vehicle: true } } } });
    this.rt.emitTo(`customer:${ride!.customerId}`, 'captain_assigned', ride);
    return ride;
  }

  async start(rideId: string, captainId: string, otp: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, captainId, status: 'ACCEPTED' } });
    if (!ride || ride.otp !== otp) throw new BadRequestException('Invalid OTP');
    const u = await this.prisma.ride.update({ where: { id: rideId }, data: { status: 'STARTED' } });
    this.rt.emitTo(`customer:${ride.customerId}`, 'ride_started', u);
    return u;
  }

  async complete(rideId: string, captainId: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, captainId, status: 'STARTED' } });
    if (!ride) throw new BadRequestException('Ride not in progress');
    const u = await this.prisma.ride.update({ where: { id: rideId }, data: { status: 'COMPLETED' } });
    this.rt.emitTo(`customer:${ride.customerId}`, 'ride_completed', u);
    return u;
  }
}

@Controller('rides')
@UseGuards(AuthGuard)
export class RidesController {
  constructor(private s: RidesService) {}
  @Post('request') @Roles('customer') request(@Req() r: any, @Body() b: any) { return this.s.request(r.user.sub, b); }
  @Post(':id/accept') @Roles('captain') accept(@Req() r: any, @Param('id') id: string) { return this.s.accept(id, r.user.sub); }
  @Post(':id/start') @Roles('captain') start(@Req() r: any, @Param('id') id: string, @Body('otp') otp: string) { return this.s.start(id, r.user.sub, otp); }
  @Post(':id/complete') @Roles('captain') complete(@Req() r: any, @Param('id') id: string) { return this.s.complete(id, r.user.sub); }
}
