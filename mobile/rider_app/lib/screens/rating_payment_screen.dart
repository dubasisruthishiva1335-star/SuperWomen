import 'package:flutter/material.dart';

class RiderRatingPaymentScreen extends StatefulWidget {
  const RiderRatingPaymentScreen({super.key});

  @override
  State<RiderRatingPaymentScreen> createState() => _RiderRatingPaymentScreenState();
}

class _RiderRatingPaymentScreenState extends State<RiderRatingPaymentScreen> {
  int rating = 5;
  int selectedTip = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Summary")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE8F8EE),
              child: Icon(Icons.check, color: Color(0xFF00C853), size: 36),
            ),
            const SizedBox(height: 12),
            const Text("Ride Completed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text("You arrived safely at Indiranagar Metro", style: TextStyle(color: Color(0xFF635777), fontSize: 12)),
            const SizedBox(height: 20),

            // Fare Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DEFA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Total Paid via UPI", style: TextStyle(color: Color(0xFF635777), fontSize: 13)),
                  Text("₹185", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA))),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
              children: [10, 20, 50].map((tip) {
                final isSelected = selectedTip == tip;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ChoiceChip(
                    label: Text("+ ₹$tip", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6A2CEA),
                    onSelected: (val) => setState(() => selectedTip = tip),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Submit Button
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
                    const SnackBar(content: Text("Thank you! Rating and Tip submitted successfully.")),
                  );
                },
                child: const Text("Submit & Finish ✓", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
