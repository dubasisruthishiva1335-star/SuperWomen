import 'package:flutter/material.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String selectedVehicle = 'bike';
  final TextEditingController _pickupController = TextEditingController(text: "Koramangala 80ft Rd, Bangalore");
  final TextEditingController _dropController = TextEditingController(text: "Indiranagar Metro Station");

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Choose Ride Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),

                  // SuperBike Option
                  _buildVehicleOption(
                    id: 'bike',
                    icon: "🛵",
                    title: "SuperBike",
                    subtitle: "Fastest · 3 min away",
                    price: "₹185",
                    isSelected: selectedVehicle == 'bike',
                    onTap: () => setSheetState(() => selectedVehicle = 'bike'),
                  ),
                  const SizedBox(height: 10),

                  // SuperAuto Option
                  _buildVehicleOption(
                    id: 'auto',
                    icon: "🛺",
                    title: "SuperAuto",
                    subtitle: "Comfort · 5 min away",
                    price: "₹240",
                    isSelected: selectedVehicle == 'auto',
                    onTap: () => setSheetState(() => selectedVehicle = 'auto'),
                  ),
                  const SizedBox(height: 16),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A2CEA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCaptainFoundDialog();
                      },
                      child: Text(
                        selectedVehicle == 'bike' ? "Book SuperBike (₹185) 🚀" : "Book SuperAuto (₹240) 🚀",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCaptainFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text("👩✈️ Captain Priya Found!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Priya is arriving in 3 mins on TVS Jupiter (KA01 AB 4972)."),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBFF),
                border: Border.all(color: const Color(0xFF6A2CEA)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Text("Share this OTP to Start Ride:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6A2CEA))),
                    SizedBox(height: 4),
                    Text("4 9 7 2", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA), letterSpacing: 4)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF6A2CEA), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption({
    required String id,
    required String icon,
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F3FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF6A2CEA) : const Color(0xFFE8DEFA),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF635777), fontSize: 11.5)),
                  ],
                ),
              ],
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF6A2CEA))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SuperWomen 💜", style: TextStyle(color: Color(0xFF6A2CEA), fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF4F8B), Color(0xFF6A2CEA)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Text("🛡️", style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("100% Women-Driven Safe Rides", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text("Only verified women captains. Safe 24/7.", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pickup & Destination Inputs
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DEFA)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.circle, color: Color(0xFF00C853), size: 14),
                      border: InputBorder.none,
                      hintText: "Enter Pickup Location",
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _dropController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.circle, color: Color(0xFFFF334B), size: 14),
                      border: InputBorder.none,
                      hintText: "Enter Destination",
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Find Rides Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A2CEA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showBookingSheet,
                child: const Text("Find Safe Rides →", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
