import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PrismaService, RedisService } from './common/services';
import { AuthController } from './auth/auth.controller';
import { RidesController, RidesService } from './rides/rides';
import { PaymentsController, PaymentsService } from './payments/payments';
import { AdminController } from './admin/admin.controller';
import { SafetyController } from './safety/safety.controller';
import { RealtimeGateway } from './realtime/realtime.gateway';

@Global()
@Module({
  imports: [JwtModule.register({ global: true, secret: process.env.JWT_SECRET, signOptions: { expiresIn: '30d' } })],
  controllers: [AuthController, RidesController, PaymentsController, AdminController, SafetyController],
  providers: [PrismaService, RedisService, RealtimeGateway, RidesService, PaymentsService],
  exports: [PrismaService, RedisService, RealtimeGateway],
})
export class AppModule {}
