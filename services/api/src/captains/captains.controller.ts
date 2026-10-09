import { Controller, Post, Patch, Put, Get, Body, Req, UseGuards, Injectable, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService, RedisService, AwsS3Service } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Injectable()
export class CaptainsService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private s3: AwsS3Service,
    private rt: RealtimeGateway,
  ) {}

  async onboard(captainId: string, data: { vehicleType?: string; vehicleNumber: string; model: string; color?: string; rcNumber?: string }) {
    const existing = await this.prisma.vehicle.findUnique({ where: { captainId } });
    if (existing) {
      return this.prisma.vehicle.update({
        where: { captainId },
        data: {
          number: data.vehicleNumber,
          model: data.model,
          vehicleType: data.vehicleType || 'BIKE',
          color: data.color,
          rcNumber: data.rcNumber,
        },
      });
    }

    return this.prisma.vehicle.create({
      data: {
        captainId,
        number: data.vehicleNumber,
        model: data.model,
        vehicleType: data.vehicleType || 'BIKE',
        color: data.color,
        rcNumber: data.rcNumber,
      },
    });
  }

  async uploadDocument(captainId: string, data: { documentType: string; filename: string }) {
    if (!data.documentType || !data.filename) throw new BadRequestException('documentType and filename are required');

    const s3Result = await this.s3.getPresignedUploadUrl(captainId, data.documentType, data.filename);

    const doc = await this.prisma.captainDocument.create({
      data: {
        captainId,
        documentType: data.documentType.toUpperCase(),
        documentUrl: s3Result.documentUrl,
        s3Key: s3Result.s3Key,
        verificationStatus: 'PENDING',
      },
    });

    return {
      document: doc,
      uploadUrl: s3Result.uploadUrl,
      instructions: 'Upload file directly to S3 via HTTP PUT with Content-Type header',
    };
  }

  async setAvailability(captainId: string, isOnline: boolean, lat?: number, lng?: number) {
    const captain = await this.prisma.captain.update({
      where: { id: captainId },
      data: { isOnline },
      include: { vehicle: true },
    });

    try {
      if (isOnline) {
        if (lat && lng) {
          await this.redis.geoadd('captains:online', lng, lat, captainId);
        }
        await this.redis.set(`captain:alive:${captainId}`, '1', 'EX', 300);
      } else {
        await this.redis.zrem('captains:online', captainId);
        await this.redis.del(`captain:alive:${captainId}`);
      }
    } catch {}

    return { captainId, isOnline: captain.isOnline };
  }

  async updateLocation(captainId: string, lat: number, lng: number, heading?: number, speed?: number, rideId?: string) {
    try {
      await this.redis.geoadd('captains:online', lng, lat, captainId);
      await this.redis.set(`captain:alive:${captainId}`, '1', 'EX', 300);
      await this.redis.set(`captain:loc:${captainId}`, JSON.stringify({ lat, lng, heading, speed, updatedAt: Date.now() }));
    } catch {}

    if (rideId) {
      await this.prisma.rideLocation.create({
        data: { rideId, lat, lng, speed, heading },
      }).catch(() => {});

      this.rt.emitTo(`ride:${rideId}`, 'driver_location', { lat, lng, heading, speed });
    }

    return { status: 'OK', lat, lng };
  }

  async getPendingRequests() {
    return this.prisma.ride.findMany({
      where: { status: 'SEARCHING' },
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: { customer: true },
    });
  }
}

@ApiTags('Captains')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(['captains', 'v1/captains'])
export class CaptainsController {
  constructor(private captainsService: CaptainsService) {}

  @Post('onboarding')
  @Roles('captain')
  @ApiOperation({ summary: 'Onboard captain vehicle details' })
  onboard(@Req() req: any, @Body() body: any) {
    return this.captainsService.onboard(req.user.sub, body);
  }

  @Post('documents')
  @Roles('captain')
  @ApiOperation({ summary: 'Generate AWS S3 presigned URL for KYC document upload' })
  uploadDocument(@Req() req: any, @Body() body: { documentType: string; filename: string }) {
    return this.captainsService.uploadDocument(req.user.sub, body);
  }

  @Patch('availability')
  @Roles('captain')
  @ApiOperation({ summary: 'Toggle online/offline driver status' })
  setAvailability(@Req() req: any, @Body() body: { isOnline: boolean; lat?: number; lng?: number }) {
    return this.captainsService.setAvailability(req.user.sub, body.isOnline, body.lat, body.lng);
  }

  @Put('location')
  @Roles('captain')
  @ApiOperation({ summary: 'Stream GPS coordinates with Redis geospatial caching and WebSocket broadcast' })
  updateLocation(@Req() req: any, @Body() body: { lat: number; lng: number; heading?: number; speed?: number; rideId?: string }) {
    return this.captainsService.updateLocation(req.user.sub, body.lat, body.lng, body.heading, body.speed, body.rideId);
  }

  @Get('ride-requests')
  @Roles('captain')
  @ApiOperation({ summary: 'Fetch available pending ride requests' })
  getPendingRequests() {
    return this.captainsService.getPendingRequests();
  }
}
