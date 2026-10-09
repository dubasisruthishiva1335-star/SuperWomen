import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

@Injectable() export class PrismaService extends PrismaClient {}
@Injectable()
export class RedisService extends Redis {
  constructor() {
    super(process.env.REDIS_URL || 'redis://localhost:6379', {
      maxRetriesPerRequest: null,
      enableOfflineQueue: true,
      retryStrategy: (times) => Math.min(times * 1000, 3000),
    });
    this.on('error', (err) => {
      // Suppress unhandled crash while Redis is offline
    });
  }
}

export * from './aws-s3.service';
