import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CaptainRideService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.token();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Accept incoming ride request atomically
  static Future<Map<String, dynamic>> acceptRide(String rideId) async {
    final res = await http.post(
      Uri.parse('$apiUrl/rides/$rideId/accept'),
      headers: await _headers(),
    );
    if (res.statusCode == 409) {
      throw Exception('Ride already taken by another captain');
    }
    if (res.statusCode >= 400) {
      throw Exception('Failed to accept ride: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Verify 4-digit OTP from rider and start ride
  static Future<Map<String, dynamic>> startRide(String rideId, String otp) async {
    final res = await http.post(
      Uri.parse('$apiUrl/rides/$rideId/start'),
      headers: await _headers(),
      body: jsonEncode({'otp': otp}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Invalid OTP. Please verify with rider.');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Complete ride at destination
  static Future<Map<String, dynamic>> completeRide(String rideId) async {
    final res = await http.post(
      Uri.parse('$apiUrl/rides/$rideId/complete'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to complete ride: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Trigger emergency SOS with live GPS coordinates
  static Future<void> triggerSos(String rideId, double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$apiUrl/safety/sos'),
      headers: await _headers(),
      body: jsonEncode({
        'rideId': rideId,
        'lat': lat,
        'lng': lng,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to trigger SOS');
    }
  }
}
