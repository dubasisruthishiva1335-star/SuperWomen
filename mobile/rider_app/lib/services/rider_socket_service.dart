import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class RiderSocketService {
  static final RiderSocketService _instance = RiderSocketService._internal();
  factory RiderSocketService() => _instance;
  RiderSocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  Function(Map<String, dynamic>)? onCaptainAssigned;
  Function(Map<String, dynamic>)? onRideStarted;
  Function(Map<String, dynamic>)? onCaptainLocation;
  Function(Map<String, dynamic>)? onRideCompleted;

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
    });

    socket!.on('captain_assigned', (data) {
      if (data is Map) {
        onCaptainAssigned?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('ride_started', (data) {
      if (data is Map) {
        onRideStarted?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('captain_location', (data) {
      if (data is Map) {
        onCaptainLocation?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('ride_completed', (data) {
      if (data is Map) {
        onRideCompleted?.call(Map<String, dynamic>.from(data));
      }
    });

    socket!.connect();
  }

  void joinRideRoom(String rideId) {
    if (socket != null && isConnected) {
      socket!.emit('ride:join', {'rideId': rideId});
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}
