import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/captain_ride_service.dart';
import '../services/captain_socket_service.dart';
import 'navigation_screen.dart';

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
  final CaptainSocketService _socketService = CaptainSocketService();

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    await _socketService.connect();
    if (isOnline) {
      _socketService.goOnline(12.9716, 77.5946);
    }

    _socketService.onRideRequest = (ride) {
      if (mounted) {
        _showIncomingRideModal(ride);
      }
    };

    _socketService.onPaymentReceived = (data) {
      if (mounted) {
        final amt = (data['amount'] as num?)?.toDouble() ?? 185.0;
        setState(() {
          todayEarnings += amt;
          todayRides++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.safeGreen,
            content: Text("🎉 ₹${amt.toInt()} Payment Received via UPI!"),
          ),
        );
      }
    };
  }

  void _showIncomingRideModal(Map<String, dynamic> ride) {
    int secondsLeft = 18;
    Timer? timer;
    final rideId = ride['id'] ?? '';
    final fare = (ride['fare'] as num?)?.toDouble() ?? 185.0;

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
                              "NEW RIDE REQUEST",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
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
                                  child: Text("R", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Passenger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("★ 4.9 · Verified Woman Rider", style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
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
                              child: const Text("🛵 SuperBike", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.safeGreen, size: 12),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Pickup: Koramangala 80ft Rd", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.alertRed, size: 12),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Drop: Indiranagar Metro Station", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Est. Earnings", style: TextStyle(color: AppTheme.inkSoft, fontSize: 13)),
                            Text("₹${fare.toInt()}", style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 26, fontWeight: FontWeight.w900)),
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
                          onPressed: () async {
                            timer?.cancel();
                            Navigator.of(context).pop();
                            try {
                              final acceptedRide = await CaptainRideService.acceptRide(rideId);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CaptainNavigationScreen(ride: acceptedRide),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CaptainNavigationScreen(ride: ride),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text("✓ ACCEPT RIDE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
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
          // Map Background
          Container(
            color: const Color(0xFFE8DEFA),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryPurple, size: 48),
                  Text("Live Map · Ready for Requests", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
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
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 6)),
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
                        if (val) {
                          _socketService.goOnline(12.9716, 77.5946);
                        } else {
                          _socketService.goOffline();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Stats & Simulation Option
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
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 4)),
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

                // Button to simulate an incoming ride locally
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13072E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.notifications_active, color: AppTheme.accentPink),
                    label: const Text("Simulate Incoming Ride Request (Test)", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      _showIncomingRideModal({
                        'id': 'simulated-ride-123',
                        'fare': 185.0,
                        'pickupLat': 12.9716,
                        'pickupLng': 77.5946,
                        'dropLat': 12.9784,
                        'dropLng': 77.6408,
                      });
                    },
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
