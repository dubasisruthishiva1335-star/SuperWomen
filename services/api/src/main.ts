import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { rawBody: true }); // rawBody needed for Razorpay webhook signature
  app.enableCors({ origin: (process.env.CORS_ORIGINS || 'http://localhost:3001').split(',') });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.listen(3000);
  console.log('API + Realtime running on :3000');
}
bootstrap();
