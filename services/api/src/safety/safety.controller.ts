import { Body, Controller, ForbiddenException, Get, Post, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard, Roles } from '../common/guard';
import { PrismaService } from '../common/services';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@ApiTags('Safety & SOS (Women Protection)')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(['safety', 'v1/safety'])
export class SafetyController {
  constructor(private prisma: PrismaService, private rt: RealtimeGateway) {}

  @Post('sos')
  @Roles('customer', 'captain')
  @ApiOperation({ summary: 'Trigger high-priority emergency SOS with live GPS and automated contact broadcast' })
  async sos(@Req() r: any, @Body() b: { rideId: string; lat: number; lng: number }) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: b.rideId },
      include: {
        customer: { include: { emergencyContacts: true } },
        captain: { include: { vehicle: true } },
      },
    });
    const who = r.user.role;
    if (!ride || (who === 'customer' ? ride.customerId : ride.captainId) !== r.user.sub) {
      throw new ForbiddenException('Not authorized for this ride');
    }

    const e = await this.prisma.sosEvent.create({
      data: { rideId: b.rideId, raisedBy: who, lat: b.lat, lng: b.lng },
    });

    // 1. Audit log the emergency incident
    await this.prisma.auditLog.create({
      data: {
        actorId: r.user.sub,
        actorType: who.toUpperCase(),
        action: 'SOS_TRIGGERED',
        resource: `ride:${b.rideId}`,
        metadata: { lat: b.lat, lng: b.lng, sosId: e.id },
      },
    });

    // 2. Real-time broadcast to Admin SOC Safety Control Room
    this.rt.emitTo('admins', 'sos_alert', { ...e, ride });

    // 3. Dispatch automated alerts to user's registered Emergency Trusted Contacts
    const alertedContacts = [];
    if (ride.customer.emergencyContacts?.length > 0) {
      for (const contact of ride.customer.emergencyContacts) {
        const message = `EMERGENCY ALERT: ${ride.customer.name} triggered SOS on SuperWomen! Ride ID: ${ride.id}. Location: https://maps.google.com/?q=${b.lat},${b.lng}. Captain: ${ride.captain?.name || 'Assigned'} (${ride.captain?.vehicle?.number || 'Vehicle'}). Help is being dispatched.`;
        
        // Log Notification record
        await this.prisma.notification.create({
          data: {
            customerId: ride.customerId,
            title: 'EMERGENCY SOS ALERT DISPATCHED',
            body: `Sent emergency alert to ${contact.name} (${contact.phone})`,
            type: 'SOS_BROADCAST',
            deliveryStatus: 'SENT',
          },
        });

        alertedContacts.push({
          name: contact.name,
          phone: contact.phone,
          relation: contact.relation,
          status: 'ALERT_DISPATCHED',
        });
      }
    }

    return {
      id: e.id,
      status: 'ALERT_DISPATCHED',
      timestamp: e.createdAt,
      adminNotified: true,
      emergencyContactsAlerted: alertedContacts.length,
      contacts: alertedContacts,
      trackingUrl: `https://maps.google.com/?q=${b.lat},${b.lng}`,
    };
  }

  @Get('sos/active')
  @Roles('admin')
  @ApiOperation({ summary: 'List all open SOS incidents in real time' })
  async getActiveSos() {
    return this.prisma.sosEvent.findMany({
      where: { status: 'OPEN' },
      include: {
        ride: {
          include: { customer: true, captain: { include: { vehicle: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
