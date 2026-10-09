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
      Uri.parse('$apiUrl/v1/rides/$rideId/accept'),
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

  /// Mark captain arrived at pickup location
  static Future<Map<String, dynamic>> markArrived(String rideId) async {
    final res = await http.post(
      Uri.parse('$apiUrl/v1/rides/$rideId/arrive'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to mark arrival: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Verify 4-digit OTP from rider and start ride
  static Future<Map<String, dynamic>> startRide(String rideId, String otp) async {
    final res = await http.post(
      Uri.parse('$apiUrl/v1/rides/$rideId/start'),
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
      Uri.parse('$apiUrl/v1/rides/$rideId/complete'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to complete ride: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Upload driver KYC document to AWS S3
  static Future<Map<String, dynamic>> uploadKycDocument(String documentType, String filename) async {
    final res = await http.post(
      Uri.parse('$apiUrl/v1/captains/documents'),
      headers: await _headers(),
      body: jsonEncode({
        'documentType': documentType,
        'filename': filename,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to get AWS S3 upload URL: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Stream live GPS coordinates to Redis geospatial index & WebSocket room
  static Future<void> streamLocation(double lat, double lng, {double? heading, double? speed, String? rideId}) async {
    await http.put(
      Uri.parse('$apiUrl/v1/captains/location'),
      headers: await _headers(),
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        'rideId': rideId,
      }),
    );
  }

  /// Toggle online/offline availability status
  static Future<void> setAvailability(bool isOnline, {double? lat, double? lng}) async {
    await http.patch(
      Uri.parse('$apiUrl/v1/captains/availability'),
      headers: await _headers(),
      body: jsonEncode({
        'isOnline': isOnline,
        'lat': lat,
        'lng': lng,
      }),
    );
  }

  /// Trigger emergency SOS with live GPS coordinates
  static Future<void> triggerSos(String rideId, double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$apiUrl/v1/safety/sos'),
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
