import { Body, Controller, ForbiddenException, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Controller('safety')
@UseGuards(AuthGuard)
export class SafetyController {
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  @Post('sos') @Roles('customer', 'captain')
  async sos(@Req() r: any, @Body() b: { rideId: string; lat: number; lng: number }) {
    const ride = await this.prisma.ride.findUnique({ where: { id: b.rideId }, include: { customer: true, captain: { include: { vehicle: true } } } });
    const who = r.user.role;
    if (!ride || (who === 'customer' ? ride.customerId : ride.captainId) !== r.user.sub) throw new ForbiddenException();
    const e = await this.prisma.sosEvent.create({ data: { rideId: b.rideId, raisedBy: who, lat: b.lat, lng: b.lng } });
    this.rt.emitTo('admins', 'sos_alert', { ...e, ride });
    return { id: e.id };
  }
}
