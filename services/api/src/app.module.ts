import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PrismaService, RedisService, AwsS3Service } from './common/services';
import { AuthController } from './auth/auth.controller';
import { RidesController, RidesService } from './rides/rides';
import { PaymentsController, PaymentsService } from './payments/payments';
import { AdminController } from './admin/admin.controller';
import { SafetyController } from './safety/safety.controller';
import { UsersController, UsersService } from './users/users.controller';
import { CaptainsController, CaptainsService } from './captains/captains.controller';
import { DispatchController, DispatchService } from './dispatch/dispatch.controller';
import { RealtimeGateway } from './realtime/realtime.gateway';

@Global()
@Module({
  imports: [
    JwtModule.register({
      global: true,
      secret: process.env.JWT_SECRET || 'superwomen-secure-jwt-secret-key-2026',
      signOptions: { expiresIn: '30d' },
    }),
  ],
  controllers: [
    AuthController,
    UsersController,
    CaptainsController,
    DispatchController,
    RidesController,
    PaymentsController,
    AdminController,
    SafetyController,
  ],
  providers: [
    PrismaService,
    RedisService,
    AwsS3Service,
    RealtimeGateway,
    UsersService,
    CaptainsService,
    DispatchService,
    RidesService,
    PaymentsService,
  ],
  exports: [PrismaService, RedisService, AwsS3Service, RealtimeGateway],
})
export class AppModule {}
