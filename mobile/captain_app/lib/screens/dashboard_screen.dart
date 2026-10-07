import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CaptainDashboardScreen extends StatefulWidget {
  const CaptainDashboardScreen({super.key});

  @override
  State<CaptainDashboardScreen> createState() => _CaptainDashboardScreenState();
}

class _CaptainDashboardScreenState extends State<CaptainDashboardScreen> {
  bool isOnline = true;
  double todayEarnings = 1240.0;
  int todayRides = 8;
  String onlineHours = "4h 22m";

  void _showRideRequestAlert() {
    int secondsLeft = 18;
    Timer? timer;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft > 0) {
                setModalState(() => secondsLeft--);
              } else {
                t.cancel();
                Navigator.of(context).pop();
              }
            });

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF13072E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOUD ALERT HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA78BFA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text("🔔", style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Text(
                              "RIDE REQUEST · INCOMING",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        // 18s Countdown Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPink,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            "${secondsLeft}s",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // PASSENGER & FARE DETAILS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.purpleTint,
                                  child: Text("P", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Priya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("★ 4.8 · Frequent rider", style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.purpleTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("🛵 Bike Ride", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.safeGreen, size: 12),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Pickup · 2.4 km away (Koramangala 80ft Rd)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.alertRed, size: 12),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Drop · 8.7 km (Indiranagar Metro Station)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Est. Earnings", style: TextStyle(color: AppTheme.inkSoft, fontSize: 13)),
                            Text("₹185", style: TextStyle(color: AppTheme.primaryPurple, fontSize: 26, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DECLINE & ACCEPT BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            timer?.cancel();
                            Navigator.of(context).pop();
                          },
                          child: const Text("DECLINE", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            timer?.cancel();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Ride Accepted! Navigate to Koramangala pickup.")),
                            );
                          },
                          child: const Text("✓ ACCEPT RIDE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Placeholder (Integrates GoogleMaps / OlaMaps in production)
          Container(
            color: const Color(0xFFE8DEFA),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryPurple, size: 48),
                  Text("Rapido-style Map View Active", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                ],
              ),
            ),
          ),

          // Top Floating Online Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF4614A8)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOnline ? "You're Online" : "You're Offline",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          isOnline ? "🟢 Receiving ride requests" : "🔴 Tap switch to go online",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeColor: Colors.white,
                      activeTrackColor: AppTheme.safeGreen,
                      onChanged: (val) {
                        setState(() => isOnline = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Stats & Test Alert Button
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // 3-Grid Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCol("Today's Earnings", "₹${todayEarnings.toInt()}", Icons.currency_rupee),
                      _buildStatCol("Rides", "$todayRides", Icons.two_wheeler),
                      _buildStatCol("Online Hours", onlineHours, Icons.timer_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Button to simulate incoming 18s loud ride request
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13072E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.notifications_active, color: AppTheme.accentPink),
                    label: const Text("Simulate Incoming Ride Request (18s Alert)", style: TextStyle(color: Colors.white)),
                    onPressed: _showRideRequestAlert,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPurple, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
      ],
    );
  }
}
