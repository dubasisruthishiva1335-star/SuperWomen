import { Controller, Get, Post, Patch, Param, Body, Query, Req, UseGuards, Injectable, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';

@Injectable()
export class SupportService {
  constructor(private prisma: PrismaService) {}

  async createTicket(userId: string, role: string, data: { category: string; subject: string; description: string; rideId?: string }) {
    return this.prisma.supportTicket.create({
      data: {
        customerId: role === 'customer' ? userId : null,
        captainId: role === 'captain' ? userId : null,
        rideId: data.rideId || null,
        category: data.category || 'GENERAL',
        subject: data.subject,
        description: data.description,
        status: 'OPEN',
      },
    });
  }

  async getUserTickets(userId: string, role: string) {
    if (role === 'captain') {
      return this.prisma.supportTicket.findMany({
        where: { captainId: userId },
        orderBy: { createdAt: 'desc' },
      });
    }
    return this.prisma.supportTicket.findMany({
      where: { customerId: userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllTickets(status?: string) {
    return this.prisma.supportTicket.findMany({
      where: status ? { status } : undefined,
      include: {
        customer: true,
        captain: true,
        ride: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateTicketStatus(id: string, status: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException('Support ticket not found');

    return this.prisma.supportTicket.update({
      where: { id },
      data: { status },
    });
  }
}

@ApiTags('Support Tickets')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(['support', 'v1/support'])
export class SupportController {
  constructor(private supportService: SupportService) {}

  @Post('tickets')
  @ApiOperation({ summary: 'Submit a new customer or driver support ticket' })
  create(
    @Req() req: any,
    @Body() body: { category: string; subject: string; description: string; rideId?: string },
  ) {
    return this.supportService.createTicket(req.user.sub, req.user.role, body);
  }

  @Get('tickets')
  @ApiOperation({ summary: 'List tickets created by the authenticated user' })
  listUserTickets(@Req() req: any) {
    return this.supportService.getUserTickets(req.user.sub, req.user.role);
  }

  @Get('admin/tickets')
  @Roles('admin')
  @ApiOperation({ summary: 'Admin list all platform support tickets' })
  listAllTickets(@Query('status') status?: string) {
    return this.supportService.getAllTickets(status);
  }

  @Patch('admin/tickets/:id/status')
  @Roles('admin')
  @ApiOperation({ summary: 'Admin update support ticket resolution status' })
  updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.supportService.updateTicketStatus(id, status);
  }
}
