import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

class AuthService {
  final _fb = FirebaseAuth.instance;
  String? _verificationId;
  String? _phone;
  bool _useBackendFallback = false;

  Future<void> sendOtp(String phone, {required void Function() onSent, required void Function(String) onError}) async {
    _phone = phone;
    _useBackendFallback = false;

    try {
      await _fb.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (cred) async {
          await _fb.signInWithCredential(cred);
        },
        verificationFailed: (e) async {
          // If Firebase SMS region is not enabled or fails, fallback to backend OTP service
          if (e.code == 'operation-not-allowed' || e.message?.contains('region') == true || e.code.contains('sms')) {
            await _triggerBackendOtp(phone, onSent: onSent, onError: onError);
          } else {
            onError(e.message ?? 'OTP failed');
          }
        },
        codeSent: (id, _) {
          _verificationId = id;
          onSent();
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (_) {
      await _triggerBackendOtp(phone, onSent: onSent, onError: onError);
    }
  }

  Future<void> _triggerBackendOtp(String phone, {required void Function() onSent, required void Function(String) onError}) async {
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/v1/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (res.statusCode < 400) {
        _useBackendFallback = true;
        onSent();
      } else {
        onError('Failed to send OTP via SMS gateway');
      }
    } catch (e) {
      onError('Connection error to auth server');
    }
  }

  Future<String> verifyOtp(String code, {required String role, String? name}) async {
    if (_useBackendFallback || _verificationId == null) {
      final res = await http.post(
        Uri.parse('$apiUrl/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phone, 'code': code, 'role': role, 'name': name}),
      );
      if (res.statusCode >= 300) throw Exception('Invalid OTP code');
      final token = jsonDecode(res.body)['token'] as String;
      (await SharedPreferences.getInstance()).setString('jwt', token);
      return token;
    }

    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code);
      final user = (await _fb.signInWithCredential(cred)).user!;
      final idToken = await user.getIdToken();
      final res = await http.post(
        Uri.parse('$apiUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken, 'role': role, 'name': name}),
      );
      if (res.statusCode >= 300) throw Exception('Login failed');
      final token = jsonDecode(res.body)['token'] as String;
      (await SharedPreferences.getInstance()).setString('jwt', token);
      return token;
    } catch (e) {
      // Fallback verification with direct code
      final res = await http.post(
        Uri.parse('$apiUrl/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phone, 'code': code, 'role': role, 'name': name}),
      );
      if (res.statusCode >= 300) throw Exception('Invalid OTP code');
      final token = jsonDecode(res.body)['token'] as String;
      (await SharedPreferences.getInstance()).setString('jwt', token);
      return token;
    }
  }

  static Future<String?> token() async => (await SharedPreferences.getInstance()).getString('jwt');
}
