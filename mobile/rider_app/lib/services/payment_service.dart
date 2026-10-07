import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'auth_service.dart';

class PaymentService {
  final _rzp = Razorpay();
  void Function()? _onSuccess;
  void Function(String)? _onFail;
  String? _orderId;

  PaymentService() {
    _rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _success);
    _rzp.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) => _onFail?.call(r.message ?? 'Payment failed'));
  }

  Future<Map<String, String>> _headers() async => {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await AuthService.token()}'};

  /// Amount is decided by the server from the ride's fare. Opens Razorpay checkout with UPI available.
  Future<void> pay(String rideId, {required String phone, required void Function() onSuccess, required void Function(String) onFail}) async {
    _onSuccess = onSuccess; _onFail = onFail;
    final res = await http.post(Uri.parse('$apiUrl/payments/order'), headers: await _headers(), body: jsonEncode({'rideId': rideId}));
    if (res.statusCode >= 300) return onFail('Could not start payment');
    final o = jsonDecode(res.body);
    _orderId = o['orderId'];
    _rzp.open({
      'key': o['keyId'], 'order_id': o['orderId'], 'amount': o['amount'], 'currency': 'INR',
      'name': 'Super Women Rapido', 'description': 'Ride payment',
      'prefill': {'contact': phone},
      'theme': {'color': '#E91E63'},
    });
  }

  Future<void> _success(PaymentSuccessResponse r) async {
    final res = await http.post(Uri.parse('$apiUrl/payments/verify'), headers: await _headers(),
        body: jsonEncode({'orderId': r.orderId ?? _orderId, 'paymentId': r.paymentId, 'signature': r.signature}));
    res.statusCode < 300 ? _onSuccess?.call() : _onFail?.call('Payment verification failed');
  }

  void dispose() => _rzp.clear();
}
