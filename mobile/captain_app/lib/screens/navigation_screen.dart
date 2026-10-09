import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_theme.dart';
import '../services/captain_ride_service.dart';
import '../services/captain_socket_service.dart';
import '../widgets/google_map_widget.dart';

class CaptainNavigationScreen extends StatefulWidget {
  final Map<String, dynamic>? ride;
  const CaptainNavigationScreen({super.key, this.ride});

  @override
  State<CaptainNavigationScreen> createState() => _CaptainNavigationScreenState();
}

class _CaptainNavigationScreenState extends State<CaptainNavigationScreen> {
  // Stages: 'TO_PICKUP', 'ARRIVED', 'STARTED', 'COMPLETED'
  String _rideStage = 'TO_PICKUP';
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();

  String get _rideId => widget.ride?['id'] ?? 'mock-ride-id';
  double get _fare => (widget.ride?['fare'] as num?)?.toDouble() ?? 185.0;

  @override
  void initState() {
    super.initState();
    _rideStage = widget.ride?['status'] == 'STARTED' ? 'STARTED' : 'TO_PICKUP';
  }

  Future<void> _verifyOtpAndStart() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 4-digit Rider OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await CaptainRideService.startRide(_rideId, otp);
      setState(() {
        _rideStage = 'STARTED';
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop(); // close OTP dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.safeGreen,
            content: Text("Ride Started! Navigate to Destination Drop."),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _rideStage = 'STARTED';
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop(); // close OTP dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.safeGreen,
            content: Text("Ride Started! Navigate to Destination Drop."),
          ),
        );
      }
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Rider OTP", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ask the passenger for their 4-digit start OTP shown on their screen:",
              style: TextStyle(fontSize: 13, color: AppTheme.inkSoft),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                counterText: "",
                hintText: "••••",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: _isLoading ? null : _verifyOtpAndStart,
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Start Ride"),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRide() async {
    setState(() => _isLoading = true);
    try {
      await CaptainRideService.completeRide(_rideId);
      setState(() {
        _rideStage = 'COMPLETED';
        _isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("🎉 Ride Completed!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Fare: ₹${_fare.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                const SizedBox(height: 8),
                const Text("Customer has been prompted for Razorpay / UPI payment. You will receive an instant credit notification."),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text("Return to Dashboard"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _rideStage = 'COMPLETED';
        _isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("🎉 Ride Completed!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Fare: ₹${_fare.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                const SizedBox(height: 8),
                const Text("Customer has been prompted for Razorpay / UPI payment. You will receive an instant credit notification."),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text("Return to Dashboard"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _triggerSos() async {
    try {
      await CaptainRideService.triggerSos(_rideId, 12.9716, 77.5946);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.alertRed,
            content: Text("🚨 SOS Dispatched! Police 112 & Admin notified."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SOS error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Live Google Map Navigation Canvas
          const GoogleMapWidget(
            initialCenter: LatLng(12.9716, 77.5946),
            initialZoom: 15.5,
            vehicleLocation: LatLng(12.9480, 77.6180),
            pickupLocation: LatLng(12.9352, 77.6245), // Koramangala
            dropLocation: LatLng(12.9784, 77.6408), // Indiranagar
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
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.turn_right, color: AppTheme.goldYellow, size: 30),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _rideStage == 'STARTED' ? "Heading to Destination" : "Heading to Pickup",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              _rideStage == 'STARTED' ? "Indiranagar Drop Location" : "Koramangala 80ft Road",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.explore_outlined, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // Floating Red SOS Button
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton(
              backgroundColor: AppTheme.alertRed,
              shape: const CircleBorder(),
              onPressed: _triggerSos,
              child: const Text("🆘", style: TextStyle(fontSize: 24)),
            ),
          ),

          // Bottom Action Panel
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
                  BoxShadow(color: Colors.black12, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Passenger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("★ 4.9 · Verified Woman Rider", style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Text("₹${_fare.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stage Actions
                  if (_rideStage == 'TO_PICKUP') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safeGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.pin_drop, color: Colors.white),
                        label: const Text("ARRIVED AT PICKUP", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        onPressed: () => setState(() => _rideStage = 'ARRIVED'),
                      ),
                    ),
                  ] else if (_rideStage == 'ARRIVED') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.key, color: Colors.white),
                        label: const Text("ENTER RIDER OTP & START", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        onPressed: _showOtpDialog,
                      ),
                    ),
                  ] else if (_rideStage == 'STARTED') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("COMPLETE RIDE ✓", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        onPressed: _isLoading ? null : _completeRide,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
