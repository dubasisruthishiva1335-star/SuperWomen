import { BadRequestException, Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@ApiTags('Admin Portal')
@ApiBearerAuth()
@Controller(['admin', 'v1/admin'])
@UseGuards(AuthGuard)
@Roles('admin')
export class AdminController {
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  @Get('stats')
  @ApiOperation({ summary: 'Platform operational overview and real-time counts' })
  async stats() {
    const [customers, captains, online, activeRides, openSos, pendingKyc] = await Promise.all([
      this.prisma.customer.count(),
      this.prisma.captain.count(),
      this.prisma.captain.count({ where: { isOnline: true } }),
      this.prisma.ride.count({ where: { status: { in: ['SEARCHING', 'ACCEPTED', 'STARTED'] } } }),
      this.prisma.sosEvent.count({ where: { status: 'OPEN' } }),
      this.prisma.captain.count({ where: { kycStatus: 'PENDING' } }),
    ]);
    return { customers, captains, online, activeRides, openSos, pendingKyc };
  }

  @Get('rides')
  @ApiOperation({ summary: 'List platform rides with status filtering' })
  rides(@Query('status') status?: string) {
    return this.prisma.ride.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: {
        customer: true,
        captain: { include: { vehicle: true } },
        payment: true,
      },
    });
  }

  @Get('captains')
  @ApiOperation({ summary: 'List captains by KYC verification status' })
  captains(@Query('status') status = 'PENDING') {
    return this.prisma.captain.findMany({
      where: { kycStatus: status },
      include: { vehicle: true, documents: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  @Patch('captains/:id/kyc')
  @ApiOperation({ summary: 'Approve or reject captain KYC documents' })
  async kyc(@Param('id') id: string, @Body('status') status: string) {
    if (!['APPROVED', 'REJECTED'].includes(status)) throw new BadRequestException('Invalid status');
    const c = await this.prisma.captain.update({
      where: { id },
      data: { kycStatus: status, ...(status === 'REJECTED' ? { isOnline: false } : {}) },
    });
    this.rt.emitTo(`captain:${id}`, 'kyc_update', { status });
    return c;
  }

  @Patch('captains/:id/status')
  @ApiOperation({ summary: 'Update captain account status and authorization' })
  async updateCaptainStatus(@Param('id') id: string, @Body() body: { kycStatus?: string; isOnline?: boolean }) {
    const c = await this.prisma.captain.update({
      where: { id },
      data: {
        ...(body.kycStatus && { kycStatus: body.kycStatus }),
        ...(body.isOnline !== undefined && { isOnline: body.isOnline }),
      },
    });
    return c;
  }

  @Get('reports')
  @ApiOperation({ summary: 'Generate platform performance, financial and safety metrics' })
  async reports() {
    const totalRides = await this.prisma.ride.count();
    const completedRides = await this.prisma.ride.count({ where: { status: 'COMPLETED' } });
    const totalPayments = await this.prisma.payment.findMany({ where: { status: 'PAID' } });
    const totalRevenuePaise = totalPayments.reduce((sum, p) => sum + p.amountPaise, 0);
    const openIncidents = await this.prisma.sosEvent.count({ where: { status: 'OPEN' } });

    return {
      totalRides,
      completedRides,
      totalRevenue: totalRevenuePaise / 100,
      currency: 'INR',
      openIncidents,
      completionRate: totalRides > 0 ? Math.round((completedRides / totalRides) * 100) : 100,
      generatedAt: new Date(),
    };
  }

  @Get('sos')
  @ApiOperation({ summary: 'List active emergency SOS safety alerts' })
  sos(@Query('status') status = 'OPEN') {
    return this.prisma.sosEvent.findMany({
      where: { status },
      orderBy: { createdAt: 'desc' },
      include: { ride: { include: { customer: true, captain: { include: { vehicle: true } } } } },
    });
  }

  @Patch('sos/:id/resolve')
  @ApiOperation({ summary: 'Resolve an active SOS safety incident' })
  resolve(@Param('id') id: string) {
    return this.prisma.sosEvent.update({ where: { id }, data: { status: 'RESOLVED', resolvedAt: new Date() } });
  }
}
