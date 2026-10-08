import { ConnectedSocket, MessageBody, OnGatewayConnection, SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';
import { PrismaService, RedisService } from '../common/services';

@WebSocketGateway({ cors: { origin: '*' } })
export class RealtimeGateway implements OnGatewayConnection {
  @WebSocketServer() server: Server;
  constructor(private jwt: JwtService, private redis: RedisService, private prisma: PrismaService) {}

  handleConnection(socket: Socket) {
    try {
      const u = this.jwt.verify(socket.handshake.auth?.token);
      socket.data.user = u;
      socket.join(`${u.role}:${u.sub}`);
      if (u.role === 'admin') socket.join('admins');
      if (u.role === 'captain') socket.join('captains:all');
    } catch { socket.disconnect(); }
  }

  emitTo(room: string, event: string, data: any) { this.server.to(room).emit(event, data); }

  @SubscribeMessage('ride:join') joinRide(@ConnectedSocket() s: Socket, @MessageBody() b: { rideId: string }) {
    if (s.data.user) s.join(`ride:${b.rideId}`);
  }

  @SubscribeMessage('captain:online')
  async online(@ConnectedSocket() s: Socket, @MessageBody() b: { lat: number; lng: number }) {
    const u = s.data.user;
    if (u?.role !== 'captain') return;
    const c = await this.prisma.captain.findUnique({ where: { id: u.sub } });
    if (c?.kycStatus !== 'APPROVED') return s.emit('error_msg', 'KYC not approved');
    await this.prisma.captain.update({ where: { id: c.id }, data: { isOnline: true } });
    s.join('captains:all');
    await this.setLoc(c.id, b.lat, b.lng);
    s.emit('online_success', { isOnline: true });
  }

  @SubscribeMessage('captain:location')
  async location(@ConnectedSocket() s: Socket, @MessageBody() b: { lat: number; lng: number; rideId?: string }) {
    const u = s.data.user;
    if (u?.role !== 'captain') return;
    await this.setLoc(u.sub, b.lat, b.lng);
    if (b.rideId) this.server.to(`ride:${b.rideId}`).emit('captain_location', { lat: b.lat, lng: b.lng });
  }

  @SubscribeMessage('captain:offline')
  async offline(@ConnectedSocket() s: Socket) {
    const u = s.data.user;
    if (u?.role !== 'captain') return;
    try {
      await this.redis.zrem('captains:online', u.sub);
    } catch {}
    s.leave('captains:all');
    await this.prisma.captain.update({ where: { id: u.sub }, data: { isOnline: false } });
    s.emit('offline_success', { isOnline: false });
  }

  // heartbeat key expires in 30s so disconnected captains stop receiving rides
  private async setLoc(id: string, lat: number, lng: number) {
    try {
      await this.redis.geoadd('captains:online', lng, lat, id);
      await this.redis.set(`captain:alive:${id}`, '1', 'EX', 30);
    } catch {}
  }
}
