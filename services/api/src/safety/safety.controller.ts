import { Body, Controller, ForbiddenException, Get, Post, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@ApiTags('Safety & SOS (Women Protection)')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(['safety', 'v1/safety'])
export class SafetyController {
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  @Post('sos')
  @Roles('customer', 'captain')
  @ApiOperation({ summary: 'Trigger high-priority emergency SOS with live GPS coordinates' })
  async sos(@Req() r: any, @Body() b: { rideId: string; lat: number; lng: number }) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: b.rideId },
      include: { customer: true, captain: { include: { vehicle: true } } },
    });
    const who = r.user.role;
    if (!ride || (who === 'customer' ? ride.customerId : ride.captainId) !== r.user.sub) {
      throw new ForbiddenException('Not authorized for this ride');
    }
    const e = await this.prisma.sosEvent.create({
      data: { rideId: b.rideId, raisedBy: who, lat: b.lat, lng: b.lng },
    });

    // Real-time broadcast to Admin SOC team
    this.rt.emitTo('admins', 'sos_alert', { ...e, ride });
    return { id: e.id, status: 'ALERT_DISPATCHED', timestamp: e.createdAt };
  }

  @Get('sos/active')
  @Roles('admin')
  @ApiOperation({ summary: 'List all open SOS incidents in real time' })
  async getActiveSos() {
    return this.prisma.sosEvent.findMany({
      where: { status: 'OPEN' },
      include: {
        ride: {
          include: { customer: true, captain: { include: { vehicle: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
