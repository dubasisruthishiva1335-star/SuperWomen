import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

@Injectable() export class PrismaService extends PrismaClient {}
@Injectable()
export class RedisService extends Redis {
  constructor() {
    super(process.env.REDIS_URL || 'redis://localhost:6379', {
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
      connectTimeout: 800,
      commandTimeout: 800,
      retryStrategy: () => null, // Do not endlessly reconnect when offline
    });
    this.on('error', () => {
      // Suppress unhandled crash while Redis is offline
    });
  }
}

export * from './aws-s3.service';
