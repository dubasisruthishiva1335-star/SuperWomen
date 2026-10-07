import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CaptainNavigationScreen extends StatelessWidget {
  const CaptainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Canvas Placeholder
          Container(
            color: const Color(0xFFE8DEFA),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, color: AppTheme.primaryPurple, size: 54),
                  SizedBox(height: 8),
                  Text("Live Route Navigation Active", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                ],
              ),
            ),
          ),

          // Top Directions Banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF180934),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.turn_right, color: AppTheme.goldYellow, size: 30),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Turn Right on 80ft Rd", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text("200m to Pickup · Koramangala", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.explore_outlined, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // Floating Red SOS Button
          Positioned(
            right: 16,
            bottom: 260,
            child: FloatingActionButton(
              backgroundColor: AppTheme.alertRed,
              shape: const CircleBorder(),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("🚨 EMERGENCY SOS DISPATCH"),
                    content: const Text("Police Control Room (112) and your emergency contacts will be immediately alerted with live GPS audio."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🚨 SOS Triggered! Ops & Police Dispatch Notified.")),
                          );
                        },
                        child: const Text("CONFIRM SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("🆘", style: TextStyle(fontSize: 22)),
            ),
          ),

          // Bottom Sheet: Passenger Details + OTP Box + Big Green Start Trip Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Passenger Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            backgroundColor: AppTheme.purpleTint,
                            child: Text("P", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Priya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("★ 4.8 · Waiting at Starbucks", style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        icon: const Icon(Icons.call, size: 16, color: Colors.white),
                        label: const Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // OTP Box Prompt
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleTint,
                      border: Border.all(color: AppTheme.primaryPurple, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: const [
                        Text("Ask passenger for OTP to START trip:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                        SizedBox(height: 4),
                        Text(
                          "4 9 7 2",
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // BIG Green Start Trip Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.safeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🚀 OTP 4972 Verified! Trip to Indiranagar started.")),
                        );
                      },
                      child: const Text("🚀 START TRIP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
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
