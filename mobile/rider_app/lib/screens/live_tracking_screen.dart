import 'package:flutter/material.dart';

class RiderLiveTrackingScreen extends StatelessWidget {
  const RiderLiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            color: const Color(0xFFE8DEFA),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.two_wheeler, color: Color(0xFF6A2CEA), size: 54),
                  SizedBox(height: 8),
                  Text("Live Ride Tracking to Indiranagar", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A2CEA))),
                ],
              ),
            ),
          ),

          // Top Info Pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF13072E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("On the way to Indiranagar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("ETA: 14 mins · Speed: 32 km/h", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    Text("🛡️ Safe Zone", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // SOS Button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFF334B),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🚨 SOS Triggered! 112 Police & Family SMS Sent.")),
                );
              },
              child: const Text("🆘", style: TextStyle(fontSize: 22)),
            ),
          ),

          // Bottom Details Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Captain Priya Sharma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("TVS Jupiter · KA01 AB 4972", style: TextStyle(color: Color(0xFF635777), fontSize: 12)),
                        ],
                      ),
                      Text("₹185", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share, color: Color(0xFF6A2CEA)),
                      label: const Text("Share Live Location with Family", style: TextStyle(color: Color(0xFF6A2CEA), fontWeight: FontWeight.bold)),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
