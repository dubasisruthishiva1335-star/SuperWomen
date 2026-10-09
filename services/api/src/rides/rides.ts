import { BadRequestException, Body, ConflictException, Controller, Get, Injectable, NotFoundException, Param, Post, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
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

  fare(d: any) { return Math.max(50, Math.round(30 + 12 * km(d.pickupLat, d.pickupLng, d.dropLat, d.dropLng))); }

  async request(customerId: string, d: any) {
    const calculatedFare = this.fare(d);
    const distanceKm = Math.round(km(d.pickupLat, d.pickupLng, d.dropLat, d.dropLng) * 10) / 10;
    const durationMins = Math.max(4, Math.round(distanceKm * 3.2));

    const ride = await this.prisma.ride.create({
      data: {
        customerId,
        pickupLat: d.pickupLat,
        pickupLng: d.pickupLng,
        pickupAddress: d.pickupAddress || 'Pickup Point',
        dropLat: d.dropLat,
        dropLng: d.dropLng,
        dropAddress: d.dropAddress || 'Destination',
        distanceKm,
        durationMins,
        vehicleType: d.vehicleType || 'BIKE',
        fare: calculatedFare,
        farePaise: calculatedFare * 100,
        otp: String(randomInt(1000, 10000)),
        status: 'SEARCHING',
      },
    });

    const { otp, ...publicRide } = ride;
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

  async getRide(rideId: string) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
      include: {
        captain: { include: { vehicle: true } },
        customer: true,
        payment: true,
        rating: true,
      },
    });
    if (!ride) throw new NotFoundException('Ride not found');
    return ride;
  }

  async getHistory(userId: string, role: string) {
    if (role === 'captain') {
      return this.prisma.ride.findMany({
        where: { captainId: userId },
        orderBy: { createdAt: 'desc' },
        take: 20,
        include: { customer: true, payment: true },
      });
    }
    return this.prisma.ride.findMany({
      where: { customerId: userId },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { captain: { include: { vehicle: true } }, payment: true },
    });
  }

  async cancel(rideId: string, actorId: string, reason?: string) {
    const ride = await this.prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new NotFoundException('Ride not found');
    if (ride.status === 'COMPLETED' || ride.status === 'CANCELLED') {
      throw new BadRequestException(`Cannot cancel ride with status ${ride.status}`);
    }

    const updated = await this.prisma.ride.update({
      where: { id: rideId },
      data: { status: 'CANCELLED' },
    });

    this.rt.emitTo(`ride:${rideId}`, 'ride_cancelled', { rideId, reason });
    if (ride.captainId) this.rt.emitTo(`captain:${ride.captainId}`, 'ride_cancelled', { rideId, reason });
    this.rt.emitTo(`customer:${ride.customerId}`, 'ride_cancelled', { rideId, reason });
    return updated;
  }

  async arrive(rideId: string, captainId: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, captainId } });
    if (!ride) throw new NotFoundException('Active ride not found');

    const updated = await this.prisma.ride.update({
      where: { id: rideId },
      data: { status: 'CAPTAIN_ARRIVED' },
    });

    this.rt.emitTo(`customer:${ride.customerId}`, 'captain_arrived', { rideId });
    return updated;
  }

  async accept(rideId: string, captainId: string) {
    const r = await this.prisma.ride.updateMany({
      where: { id: rideId, status: 'SEARCHING', captainId: null },
      data: { captainId, status: 'ACCEPTED' },
    });
    if (!r.count) throw new ConflictException('Ride already taken or cancelled');

    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
      include: { captain: { include: { vehicle: true } } },
    });
    this.rt.emitTo(`customer:${ride!.customerId}`, 'captain_assigned', ride);
    return ride;
  }

  async start(rideId: string, captainId: string, otp: string) {
    const ride = await this.prisma.ride.findFirst({
      where: { id: rideId, captainId, status: { in: ['ACCEPTED', 'CAPTAIN_ARRIVED'] } },
    });
    if (!ride || ride.otp !== otp) throw new BadRequestException('Invalid OTP');

    const u = await this.prisma.ride.update({ where: { id: rideId }, data: { status: 'STARTED' } });
    this.rt.emitTo(`customer:${ride.customerId}`, 'ride_started', u);
    return u;
  }

  async complete(rideId: string, captainId: string) {
    const ride = await this.prisma.ride.findFirst({ where: { id: rideId, captainId, status: 'STARTED' } });
    if (!ride) throw new BadRequestException('Ride not in progress');

    const u = await this.prisma.ride.update({ where: { id: rideId }, data: { status: 'COMPLETED' } });
    // Update captain stats
    await this.prisma.captain.update({
      where: { id: captainId },
      data: { totalRides: { increment: 1 } },
    }).catch(() => {});

    this.rt.emitTo(`customer:${ride.customerId}`, 'ride_completed', u);
    return u;
  }

  async rateRide(rideId: string, customerId: string, score: number, comment?: string, tags: string[] = []) {
    const ride = await this.prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride || !ride.captainId) throw new NotFoundException('Ride not found');

    const rating = await this.prisma.rating.create({
      data: {
        rideId,
        customerId,
        captainId: ride.captainId,
        score,
        comment,
        tags,
      },
    });

    // Update Captain rolling average rating
    const allRatings = await this.prisma.rating.findMany({ where: { captainId: ride.captainId } });
    const avg = allRatings.reduce((acc, cur) => acc + cur.score, 0) / allRatings.length;
    await this.prisma.captain.update({
      where: { id: ride.captainId },
      data: { ratingAvg: Math.round(avg * 10) / 10 },
    });

    return rating;
  }
}

@ApiTags('Rides')
@ApiBearerAuth()
@Controller(['rides', 'v1/rides'])
@UseGuards(AuthGuard)
export class RidesController {
  constructor(private s: RidesService) {}

  @Post('request')
  @Roles('customer')
  @ApiOperation({ summary: 'Request a new ride (Rapido style matching)' })
  requestLegacy(@Req() r: any, @Body() b: any) { return this.s.request(r.user.sub, b); }

  @Post()
  @Roles('customer')
  @ApiOperation({ summary: 'Create ride request (v1/rides)' })
  requestV1(@Req() r: any, @Body() b: any) { return this.s.request(r.user.sub, b); }

  @Get('history')
  @ApiOperation({ summary: 'Get ride booking history' })
  history(@Req() r: any) { return this.s.getHistory(r.user.sub, r.user.role); }

  @Get(':id')
  @ApiOperation({ summary: 'Get single ride details' })
  getOne(@Param('id') id: string) { return this.s.getRide(id); }

  @Post(':id/accept')
  @Roles('captain')
  @ApiOperation({ summary: 'Captain accepts a dispatched ride' })
  accept(@Req() r: any, @Param('id') id: string) { return this.s.accept(id, r.user.sub); }

  @Post(':id/arrive')
  @Roles('captain')
  @ApiOperation({ summary: 'Captain marks arrived at pickup point' })
  arrive(@Req() r: any, @Param('id') id: string) { return this.s.arrive(id, r.user.sub); }

  @Post(':id/start')
  @Roles('captain')
  @ApiOperation({ summary: 'Captain validates 4-digit OTP to start trip' })
  start(@Req() r: any, @Param('id') id: string, @Body('otp') otp: string) { return this.s.start(id, r.user.sub, otp); }

  @Post(':id/complete')
  @Roles('captain')
  @ApiOperation({ summary: 'Captain completes trip at destination' })
  complete(@Req() r: any, @Param('id') id: string) { return this.s.complete(id, r.user.sub); }

  @Post(':id/cancel')
  @ApiOperation({ summary: 'Cancel ride with optional cancellation reason' })
  cancel(@Req() r: any, @Param('id') id: string, @Body('reason') reason?: string) { return this.s.cancel(id, r.user.sub, reason); }

  @Post(':id/rating')
  @Roles('customer')
  @ApiOperation({ summary: 'Submit passenger rating & review for captain' })
  rate(@Req() r: any, @Param('id') id: string, @Body() b: { score: number; comment?: string; tags?: string[] }) {
    return this.s.rateRide(id, r.user.sub, b.score, b.comment, b.tags || []);
  }
}
