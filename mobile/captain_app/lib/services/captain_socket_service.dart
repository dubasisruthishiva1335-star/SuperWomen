import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class CaptainSocketService {
  static final CaptainSocketService _instance = CaptainSocketService._internal();
  factory CaptainSocketService() => _instance;
  CaptainSocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;
  Timer? _heartbeatTimer;

  Function(Map<String, dynamic>)? onRideRequest;
  Function(Map<String, dynamic>)? onPaymentReceived;
  Function(Map<String, dynamic>)? onKycUpdate;
  Function(String)? onErrorMsg;

  Future<void> connect() async {
    final token = await AuthService.token();
    if (token == null) return;

    if (socket != null && socket!.connected) return;

    socket = IO.io(
      apiUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.onConnect((_) {
      isConnected = true;
    });

    socket!.onDisconnect((_) {
      isConnected = false;
      _heartbeatTimer?.cancel();
    });

    socket!.on('ride_request', (data) {
      if (data is Map) {
        onRideRequest?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('payment_received', (data) {
      if (data is Map) {
        onPaymentReceived?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('kyc_update', (data) {
      if (data is Map) {
        onKycUpdate?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('error_msg', (msg) {
      onErrorMsg?.call(msg.toString());
    });

    socket!.connect();
  }

  void goOnline(double lat, double lng) {
    if (socket != null && isConnected) {
      socket!.emit('captain:online', {'lat': lat, 'lng': lng});
      _startHeartbeat(lat, lng);
    }
  }

  void goOffline() {
    _heartbeatTimer?.cancel();
    if (socket != null && isConnected) {
      socket!.emit('captain:offline');
    }
  }

  void updateLocation(double lat, double lng, {String? rideId}) {
    if (socket != null && isConnected) {
      socket!.emit('captain:location', {
        'lat': lat,
        'lng': lng,
        if (rideId != null) 'rideId': rideId,
      });
    }
  }

  void _startHeartbeat(double lat, double lng) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      updateLocation(lat, lng);
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}
