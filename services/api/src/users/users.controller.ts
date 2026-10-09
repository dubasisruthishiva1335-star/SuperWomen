import { Controller, Get, Patch, Body, Req, UseGuards, Injectable, NotFoundException } from '@nestjs/common';
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
}
