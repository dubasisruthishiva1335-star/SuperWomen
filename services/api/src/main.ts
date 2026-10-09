import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { rawBody: true });
  app.enableCors({ origin: '*' });
  app.useGlobalPipes(new ValidationPipe({ whitelist: false, transform: true }));

  // OpenAPI / Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('SuperWomen Platform APIs')
    .setDescription('Complete End-to-End Rapido-style Bike Taxi Platform Blueprint APIs. Includes Customer Booking, Captain Operations, AWS S3 KYC, Redis Geospatial Dispatch, Razorpay UPI Payments, Women Safety SOS, and Admin Operations.')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 SuperWomen Backend API running on http://localhost:${port}`);
  console.log(`📚 Swagger OpenAPI Documentation available at: http://localhost:${port}/api/docs`);
}
bootstrap();
