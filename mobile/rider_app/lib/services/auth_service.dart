import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000'); // 10.0.2.2 = host machine from Android emulator

class AuthService {
  final _fb = FirebaseAuth.instance;
  String? _verificationId;

  Future<void> sendOtp(String phone, {required void Function() onSent, required void Function(String) onError}) {
    return _fb.verifyPhoneNumber(
      phoneNumber: phone, // +91XXXXXXXXXX
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async { await _fb.signInWithCredential(cred); }, // Android auto-retrieval
      verificationFailed: (e) => onError(e.message ?? 'OTP failed'),
      codeSent: (id, _) { _verificationId = id; onSent(); },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  /// [role] is 'customer' in the Rapido app and 'captain' in the Captain app.
  Future<String> verifyOtp(String code, {required String role, String? name}) async {
    final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code);
    final user = (await _fb.signInWithCredential(cred)).user!;
    final idToken = await user.getIdToken();
    final res = await http.post(Uri.parse('$apiUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken, 'role': role, 'name': name}));
    if (res.statusCode >= 300) throw Exception('Login failed');
    final token = jsonDecode(res.body)['token'] as String;
    (await SharedPreferences.getInstance()).setString('jwt', token);
    return token;
  }

  static Future<String?> token() async => (await SharedPreferences.getInstance()).getString('jwt');
}
