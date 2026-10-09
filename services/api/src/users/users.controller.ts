import { Controller, Get, Post, Delete, Patch, Param, Body, Req, UseGuards, Injectable, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '../common/guard';
import { PrismaService } from '../common/services';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: userId },
      include: {
        rides: { take: 5, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!customer) throw new NotFoundException('User profile not found');
    return customer;
  }

  async updateProfile(userId: string, data: { name?: string; pushToken?: string }) {
    return this.prisma.customer.update({
      where: { id: userId },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.pushToken && { pushToken: data.pushToken }),
      },
    });
  }

  async getEmergencyContacts(userId: string) {
    return this.prisma.emergencyContact.findMany({
      where: { customerId: userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async addEmergencyContact(userId: string, data: { name: string; phone: string; relation?: string }) {
    return this.prisma.emergencyContact.create({
      data: {
        customerId: userId,
        name: data.name,
        phone: data.phone,
        relation: data.relation || 'FAMILY',
      },
    });
  }

  async removeEmergencyContact(userId: string, contactId: string) {
    const contact = await this.prisma.emergencyContact.findFirst({
      where: { id: contactId, customerId: userId },
    });
    if (!contact) throw new NotFoundException('Emergency contact not found');

    await this.prisma.emergencyContact.delete({ where: { id: contactId } });
    return { success: true, message: 'Emergency contact removed' };
  }
}

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(['users', 'v1/users'])
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current authenticated user profile' })
  getMe(@Req() req: any) {
    return this.usersService.getProfile(req.user.sub);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update user profile (name, push notification token)' })
  updateMe(@Req() req: any, @Body() body: { name?: string; pushToken?: string }) {
    return this.usersService.updateProfile(req.user.sub, body);
  }

  @Get('emergency-contacts')
  @ApiOperation({ summary: 'List all trusted emergency safety contacts for user' })
  getEmergencyContacts(@Req() req: any) {
    return this.usersService.getEmergencyContacts(req.user.sub);
  }

  @Post('emergency-contacts')
  @ApiOperation({ summary: 'Add a new trusted emergency contact for automated SOS alerting' })
  addEmergencyContact(
    @Req() req: any,
    @Body() body: { name: string; phone: string; relation?: string },
  ) {
    return this.usersService.addEmergencyContact(req.user.sub, body);
  }

  @Delete('emergency-contacts/:id')
  @ApiOperation({ summary: 'Remove a trusted emergency contact' })
  deleteEmergencyContact(@Req() req: any, @Param('id') id: string) {
    return this.usersService.removeEmergencyContact(req.user.sub, id);
  }
}
