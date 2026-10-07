import { BadRequestException, Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Controller('admin')
@UseGuards(AuthGuard)
@Roles('admin')
export class AdminController {
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  @Get('stats') async stats() {
    const [customers, captains, online, activeRides, openSos, pendingKyc] = await Promise.all([
      this.prisma.customer.count(), this.prisma.captain.count(), this.prisma.captain.count({ where: { isOnline: true } }),
      this.prisma.ride.count({ where: { status: { in: ['SEARCHING', 'ACCEPTED', 'STARTED'] } } }),
      this.prisma.sosEvent.count({ where: { status: 'OPEN' } }), this.prisma.captain.count({ where: { kycStatus: 'PENDING' } }),
    ]);
    return { customers, captains, online, activeRides, openSos, pendingKyc };
  }

  @Get('captains') captains(@Query('status') status = 'PENDING') {
    return this.prisma.captain.findMany({ where: { kycStatus: status }, include: { vehicle: true }, orderBy: { createdAt: 'asc' } });
  }

  @Patch('captains/:id/kyc') async kyc(@Param('id') id: string, @Body('status') status: string) {
    if (!['APPROVED', 'REJECTED'].includes(status)) throw new BadRequestException();
    const c = await this.prisma.captain.update({ where: { id }, data: { kycStatus: status, ...(status === 'REJECTED' ? { isOnline: false } : {}) } });
    this.rt.emitTo(`captain:${id}`, 'kyc_update', { status });
    return c;
  }

  @Get('sos') sos(@Query('status') status = 'OPEN') {
    return this.prisma.sosEvent.findMany({
      where: { status }, orderBy: { createdAt: 'desc' },
      include: { ride: { include: { customer: true, captain: { include: { vehicle: true } } } } },
    });
  }

  @Patch('sos/:id/resolve') resolve(@Param('id') id: string) {
    return this.prisma.sosEvent.update({ where: { id }, data: { status: 'RESOLVED', resolvedAt: new Date() } });
  }
}
