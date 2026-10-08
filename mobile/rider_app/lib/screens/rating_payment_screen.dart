import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class RiderRatingPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? ride;
  const RiderRatingPaymentScreen({super.key, this.ride});

  @override
  State<RiderRatingPaymentScreen> createState() => _RiderRatingPaymentScreenState();
}

class _RiderRatingPaymentScreenState extends State<RiderRatingPaymentScreen> {
  int rating = 5;
  int selectedTip = 20;
  bool _isPaid = false;
  bool _isPaying = false;
  late final PaymentService _paymentService;

  String get _rideId => widget.ride?['id'] ?? 'mock-ride-id';
  double get _fare => (widget.ride?['fare'] as num?)?.toDouble() ?? 185.0;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _processPayment() {
    setState(() => _isPaying = true);
    _paymentService.pay(
      _rideId,
      phone: '+919876543210',
      onSuccess: () {
        setState(() {
          _isPaid = true;
          _isPaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00C853),
            content: Text("🎉 Payment Successful via Razorpay / UPI!"),
          ),
        );
      },
      onFail: (err) {
        setState(() => _isPaying = false);
        // Fallback or test failure alert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF334B),
            content: Text(err),
            action: SnackBarAction(
              label: "Mark Paid (Test)",
              textColor: Colors.white,
              onPressed: () => setState(() => _isPaid = true),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Summary & Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _isPaid ? const Color(0xFFE8F8EE) : const Color(0xFFF3EBFF),
              child: Icon(_isPaid ? Icons.check_circle : Icons.receipt_long, color: _isPaid ? const Color(0xFF00C853) : const Color(0xFF6A2CEA), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              _isPaid ? "Ride Paid Successfully!" : "Ride Completed!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Text("You arrived safely at Indiranagar Metro Station", style: TextStyle(color: Color(0xFF635777), fontSize: 12)),
            const SizedBox(height: 20),

            // Fare Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DEFA)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Base Trip Fare", style: TextStyle(color: Color(0xFF635777), fontSize: 13)),
                      Text("₹${_fare.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (selectedTip > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Driver Tip", style: TextStyle(color: Color(0xFF635777), fontSize: 13)),
                        Text("+ ₹$selectedTip", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00C853))),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        "₹${(_fare + selectedTip).toInt()}",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Razorpay Payment Action
            if (!_isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63), // Pink brand accent
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: _isPaying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          "Pay ₹${(_fare + selectedTip).toInt()} via Razorpay / UPI",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  onPressed: _isPaying ? null : _processPayment,
                ),
              ),
              const SizedBox(height: 10),
              // Option to test cash / direct mark
              TextButton(
                onPressed: () => setState(() => _isPaid = true),
                child: const Text("Pay with Cash or Test Skip →", style: TextStyle(color: Color(0xFF6A2CEA))),
              ),
              const SizedBox(height: 20),
            ],

            // Rating Stars
            const Text("Rate Captain Priya", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: 34,
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Tip Selection
            const Text("Add a Tip for Captain", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF635777))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [0, 10, 20, 50].map((tip) {
                final isSelected = selectedTip == tip;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(tip == 0 ? "No Tip" : "+ ₹$tip", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6A2CEA),
                    onSelected: (val) => setState(() => selectedTip = tip),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Submit Button
            if (_isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A2CEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Thank you! Rating submitted.")),
                    );
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text("Submit & Finish ✓", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
