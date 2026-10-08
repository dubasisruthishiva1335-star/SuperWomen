import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RiderRideService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.token();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Request a ride: creates ride, calculates server-side fare, and broadcasts to nearby captains
  static Future<Map<String, dynamic>> requestRide({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    final res = await http.post(
      Uri.parse('$apiUrl/rides/request'),
      headers: await _headers(),
      body: jsonEncode({
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to request ride: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Trigger emergency SOS with live GPS
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
