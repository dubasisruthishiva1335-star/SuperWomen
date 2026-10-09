import { Controller, Post, Body, Param, Req, UseGuards, Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService, RedisService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

const calculateKm = (aLat: number, aLng: number, bLat: number, bLng: number) => {
  const R = 6371, r = (d: number) => (d * Math.PI) / 180;
  const x = Math.sin(r(bLat - aLat) / 2) ** 2 + Math.cos(r(aLat)) * Math.cos(r(bLat)) * Math.sin(r(bLng - aLng) / 2) ** 2;
  return Math.round(2 * R * Math.asin(Math.sqrt(x)) * 10) / 10;
};

@Injectable()
export class DispatchService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private rt: RealtimeGateway,
  ) {}

  /// Calculate fair dynamic quotes for Bike and Auto
  async getQuotes(customerId: string | null, data: { pickupLat: number; pickupLng: number; dropLat: number; dropLng: number }) {
    const distanceKm = Math.max(1.0, calculateKm(data.pickupLat, data.pickupLng, data.dropLat, data.dropLng));
    const durationMins = Math.max(4, Math.round(distanceKm * 3.2)); // avg 20km/h in city traffic

    // Bike pricing: Base ₹30 + ₹12/km, Min ₹50
    const bikeFare = Math.max(50, Math.round(30 + 12 * distanceKm));
    // Auto pricing: Base ₹40 + ₹15/km, Min ₹60
    const autoFare = Math.max(60, Math.round(40 + 15 * distanceKm));

    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min quote expiry

    const quoteBike = await this.prisma.fareQuote.create({
      data: {
        customerId,
        pickupLat: data.pickupLat,
        pickupLng: data.pickupLng,
        dropLat: data.dropLat,
        dropLng: data.dropLng,
        distanceKm,
        durationMins,
        vehicleType: 'BIKE',
        estimatedFarePaise: bikeFare * 100,
        expiresAt,
      },
    });

    const quoteAuto = await this.prisma.fareQuote.create({
      data: {
        customerId,
        pickupLat: data.pickupLat,
        pickupLng: data.pickupLng,
        dropLat: data.dropLat,
        dropLng: data.dropLng,
        distanceKm,
        durationMins,
        vehicleType: 'AUTO',
        estimatedFarePaise: autoFare * 100,
        expiresAt,
      },
    });

    return {
      distanceKm,
      durationMins,
      quotes: [
        {
          id: quoteBike.id,
          vehicleType: 'BIKE',
          title: 'SuperBike',
          subtitle: 'Fastest · Women Captain',
          fare: bikeFare,
          farePaise: bikeFare * 100,
          currency: 'INR',
          etaMins: 2,
        },
        {
          id: quoteAuto.id,
          vehicleType: 'AUTO',
          title: 'SuperAuto',
          subtitle: 'Comfort · 3-Wheeler',
          fare: autoFare,
          farePaise: autoFare * 100,
          currency: 'INR',
          etaMins: 4,
        },
      ],
      expiresAt,
    };
  }

  /// Search available captains using Redis Geospatial queries
  async searchCaptains(lat: number, lng: number, radiusKm = 8) {
    try {
      const near = (await this.redis.georadius('captains:online', lng, lat, radiusKm, 'km', 'WITHDIST', 'ASC')) as any[];
      const candidates = [];
      for (const item of near) {
        const id = Array.isArray(item) ? item[0] : item;
        const dist = Array.isArray(item) ? item[1] : 0;
        const isAlive = await this.redis.exists(`captain:alive:${id}`);
        if (isAlive) {
          const captain = await this.prisma.captain.findUnique({
            where: { id },
            include: { vehicle: true },
          });
          if (captain) candidates.push({ captain, distanceKm: dist });
        }
      }
      return candidates;
    } catch {
      // Fallback to online captains in DB
      const captains = await this.prisma.captain.findMany({
        where: { isOnline: true },
        include: { vehicle: true },
        take: 5,
      });
      return captains.map((c) => ({ captain: c, distanceKm: 1.2 }));
    }
  }

  /// Atomically assign a ride to a specific captain
  async assignRide(rideId: string, captainId: string) {
    const result = await this.prisma.ride.updateMany({
      where: { id: rideId, status: 'SEARCHING', captainId: null },
      data: { captainId, status: 'ASSIGNED' },
    });
    if (!result.count) throw new ConflictException('Ride already assigned or expired');

    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
      include: { captain: { include: { vehicle: true } }, customer: true },
    });

    this.rt.emitTo(`customer:${ride!.customerId}`, 'captain_assigned', ride);
    this.rt.emitTo(`captain:${captainId}`, 'ride_assigned', ride);
    return ride;
  }

  /// Captain rejects a dispatched ride request
  async rejectRide(rideId: string, captainId: string) {
    // Record rejection in Redis to avoid re-offering to the same captain
    await this.redis.sadd(`ride:${rideId}:declined_by`, captainId).catch(() => {});
    return { status: 'DECLINED', rideId };
  }
}

@ApiTags('Dispatch & Quotes')
@Controller(['v1', ''])
export class DispatchController {
  constructor(private dispatchService: DispatchService) {}

  @Post('quotes')
  @ApiOperation({ summary: 'Calculate dynamic fare estimates for SuperBike and SuperAuto' })
  getQuotes(@Body() body: { pickupLat: number; pickupLng: number; dropLat: number; dropLng: number }) {
    return this.dispatchService.getQuotes(null, body);
  }

  @Post('dispatch/search')
  @UseGuards(AuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Find nearby online captains using Redis geospatial indexing' })
  search(@Body() body: { lat: number; lng: number; radiusKm?: number }) {
    return this.dispatchService.searchCaptains(body.lat, body.lng, body.radiusKm);
  }

  @Post('dispatch/assign')
  @UseGuards(AuthGuard)
  @Roles('captain', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Atomically assign ride to a captain' })
  assign(@Body() body: { rideId: string; captainId: string }) {
    return this.dispatchService.assignRide(body.rideId, body.captainId);
  }

  @Post('dispatch/:rideId/reject')
  @UseGuards(AuthGuard)
  @Roles('captain')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Captain declines incoming ride offer' })
  reject(@Param('rideId') rideId: string, @Req() req: any) {
    return this.dispatchService.rejectRide(rideId, req.user.sub);
  }
}
