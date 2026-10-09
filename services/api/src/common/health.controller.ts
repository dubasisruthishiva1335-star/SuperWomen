import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('System & Health')
@Controller()
export class HealthController {
  @Get(['health', 'v1/health'])
  @ApiOperation({ summary: 'Platform operational health check and uptime probe' })
  health() {
    return {
      status: 'ok',
      service: 'SuperWomen API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.round(process.uptime()),
    };
  }
}
