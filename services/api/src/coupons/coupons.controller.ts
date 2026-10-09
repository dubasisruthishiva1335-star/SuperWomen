import { Controller, Get, Post, Body, UseGuards, Injectable, BadRequestException, NotFoundException, OnModuleInit } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '../common/guard';
import { PrismaService } from '../common/services';

@Injectable()
export class CouponsService implements OnModuleInit {
  constructor(private prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedDefaults();
  }

  async seedDefaults() {
    const count = await this.prisma.promoCode.count();
    if (count === 0) {
      await this.prisma.promoCode.createMany({
        data: [
          {
            code: 'WOMENFIRST50',
            description: '50% off on your first safe ride up to ₹50',
            discountPercent: 50,
            maxDiscountPaise: 5000,
            minRideAmountPaise: 5000,
            isActive: true,
          },
          {
            code: 'SAFETY100',
            description: 'Flat ₹100 discount for verified women night commuters',
            discountPercent: null,
            maxDiscountPaise: 10000,
            minRideAmountPaise: 12000,
            isActive: true,
          },
          {
            code: 'SUPERWOMAN',
            description: '25% discount across all city rides',
            discountPercent: 25,
            maxDiscountPaise: 4000,
            minRideAmountPaise: 4000,
            isActive: true,
          },
        ],
      });
    }
  }

  async listActive() {
    return this.prisma.promoCode.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async apply(code: string, farePaise: number) {
    const promo = await this.prisma.promoCode.findUnique({
      where: { code: code.toUpperCase() },
    });

    if (!promo || !promo.isActive) {
      throw new NotFoundException('Invalid or expired coupon code');
    }

    if (promo.expiresAt && promo.expiresAt < new Date()) {
      throw new BadRequestException('Coupon code has expired');
    }

    if (farePaise < promo.minRideAmountPaise) {
      throw new BadRequestException(
        `Minimum ride fare must be at least ₹${promo.minRideAmountPaise / 100} to use this coupon`,
      );
    }

    let discountPaise = 0;
    if (promo.discountPercent) {
      discountPaise = Math.round((farePaise * promo.discountPercent) / 100);
      if (discountPaise > promo.maxDiscountPaise) {
        discountPaise = promo.maxDiscountPaise;
      }
    } else {
      discountPaise = promo.maxDiscountPaise;
    }

    if (discountPaise > farePaise) {
      discountPaise = farePaise;
    }

    const finalFarePaise = farePaise - discountPaise;

    return {
      code: promo.code,
      description: promo.description,
      originalFarePaise: farePaise,
      discountPaise,
      finalFarePaise,
      originalFare: farePaise / 100,
      discount: discountPaise / 100,
      finalFare: finalFarePaise / 100,
    };
  }
}

@ApiTags('Coupons & Promotions')
@Controller(['coupons', 'v1/coupons'])
export class CouponsController {
  constructor(private couponsService: CouponsService) {}

  @Get()
  @ApiOperation({ summary: 'List all active discount coupon promo codes' })
  list() {
    return this.couponsService.listActive();
  }

  @Post('apply')
  @UseGuards(AuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Apply coupon code to calculate dynamic ride fare discount' })
  apply(@Body() body: { code: string; farePaise: number }) {
    if (!body.code || !body.farePaise) {
      throw new BadRequestException('code and farePaise are required');
    }
    return this.couponsService.apply(body.code, body.farePaise);
  }
}
