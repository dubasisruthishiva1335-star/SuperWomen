import { BadRequestException, Body, Controller, Post, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as admin from 'firebase-admin';
import { PrismaService } from '../common/services';

if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID || 'superwomen-7181d';
  try {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (raw && raw.trim().startsWith('{')) {
      const creds = JSON.parse(raw);
      if (creds.client_email && creds.private_key) {
        admin.initializeApp({ credential: admin.credential.cert(creds), projectId });
      } else {
        admin.initializeApp({ projectId });
      }
    } else {
      admin.initializeApp({ projectId });
    }
  } catch {
    admin.initializeApp({ projectId });
  }
}

@Controller('auth')
export class AuthController {
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

  /** Client does Firebase phone OTP, sends us the Firebase ID token. We verify it server-side and issue our own JWT. */
  @Post('verify')
  async verify(@Body() b: { idToken: string; role: 'customer' | 'captain' | 'admin'; name?: string }) {
    let phone: string | undefined;
    try { phone = (await admin.auth().verifyIdToken(b.idToken)).phone_number; }
    catch { throw new UnauthorizedException('Invalid OTP token'); }
    if (!phone) throw new UnauthorizedException('Phone not verified');

    if (b.role === 'admin') {
      const allowed = (process.env.ADMIN_PHONES || '').split(',').map((s) => s.trim());
      if (!allowed.includes(phone)) throw new UnauthorizedException('Not an admin');
      return { token: this.jwt.sign({ sub: phone, role: 'admin' }) };
    }
    if (b.role === 'customer') {
      const u = await this.prisma.customer.upsert({ where: { phone }, update: {}, create: { phone, name: b.name || 'Customer' } });
      return { token: this.jwt.sign({ sub: u.id, role: 'customer' }), user: u };
    }
    if (b.role === 'captain') {
      const u = await this.prisma.captain.upsert({ where: { phone }, update: {}, create: { phone, name: b.name || 'Captain' } });
      return { token: this.jwt.sign({ sub: u.id, role: 'captain' }), user: u };
    }
    throw new BadRequestException('Bad role');
  }
}
