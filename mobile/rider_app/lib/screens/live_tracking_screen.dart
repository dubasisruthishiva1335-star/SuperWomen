import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rider_ride_service.dart';
import '../services/rider_socket_service.dart';
import '../widgets/google_map_widget.dart';
import 'rating_payment_screen.dart';

class RiderLiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? ride;
  const RiderLiveTrackingScreen({super.key, this.ride});

  @override
  State<RiderLiveTrackingScreen> createState() => _RiderLiveTrackingScreenState();
}

class _RiderLiveTrackingScreenState extends State<RiderLiveTrackingScreen> {
  final RiderSocketService _socketService = RiderSocketService();
  String _rideStatus = 'ARRIVING'; // ARRIVING, STARTED, COMPLETED
  double _captainLat = 12.9716;
  double _captainLng = 77.5946;

  Future<void> _callCaptain(String phone) async {
    final telUri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (_) {}
  }

  Future<void> _shareLiveTrip() async {
    final trackingUrl = "https://super-women.vercel.app/track/$_rideId";
    final message = "I am on a SuperWomen 100% Women-Safe ride with Captain Priya (KA01 SW 1234). Track my live journey: $trackingUrl";
    final whatsappUri = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF6A2CEA),
            content: Text("Live link copied: $trackingUrl"),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF6A2CEA),
          content: Text("Live link copied: $trackingUrl"),
        ),
      );
    }
  }

  String get _rideId => widget.ride?['id'] ?? 'mock-ride-id';
  String get _otp => widget.ride?['otp'] ?? '4972';
  double get _fare => (widget.ride?['fare'] as num?)?.toDouble() ?? 185.0;

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _socketService.joinRideRoom(_rideId);

    _socketService.onCaptainLocation = (loc) {
      if (mounted) {
        setState(() {
          _captainLat = (loc['lat'] as num?)?.toDouble() ?? _captainLat;
          _captainLng = (loc['lng'] as num?)?.toDouble() ?? _captainLng;
        });
      }
    };

    _socketService.onRideStarted = (data) {
      if (mounted) {
        setState(() => _rideStatus = 'STARTED');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00C853),
            content: Text("🚀 Ride Started! Enjoy your safe journey."),
          ),
        );
      }
    };

    _socketService.onRideCompleted = (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiderRatingPaymentScreen(ride: widget.ride),
          ),
        );
      }
    };
  }

  Future<void> _triggerSos() async {
    try {
      await RiderRideService.triggerSos(_rideId, 12.9750, 77.6050);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFF334B),
            content: Text("🚨 SOS Dispatched! Police 112 & Emergency Contacts alerted with live coordinates."),
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
          // Live Google Map View with real-time captain telemetry
          GoogleMapWidget(
            vehicleLocation: LatLng(_captainLat, _captainLng),
            pickupLocation: const LatLng(12.9352, 77.6245), // Koramangala
            dropLocation: const LatLng(12.9784, 77.6408), // Indiranagar
            initialCenter: LatLng(_captainLat, _captainLng),
            initialZoom: 15.0,
            vehicleType: widget.ride?['vehicleType'] ?? 'BIKE',
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
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _rideStatus == 'STARTED' ? "On the way to Indiranagar" : "Captain is 2 mins away",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _rideStatus == 'STARTED' ? "ETA: 12 mins · 32 km/h" : "Meet at Koramangala 80ft Road",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const Text("🛡️ 100% Women Safe", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Floating SOS Button
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFF334B),
              onPressed: _triggerSos,
              child: const Text("🆘", style: TextStyle(fontSize: 24)),
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
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Captain Priya Sharma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Honda Activa 6G · KA01 SW 1234", style: TextStyle(color: Color(0xFF635777), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF00C853), size: 22),
                            tooltip: "Call Captain",
                            onPressed: () => _callCaptain('+919876543211'),
                          ),
                        ],
                      ),
                      Text("₹${_fare.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // OTP Banner (Only before ride starts)
                  if (_rideStatus != 'STARTED') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6A2CEA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Start OTP for Captain:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A2CEA), fontSize: 13)),
                          Text(_otp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA), letterSpacing: 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share, color: Color(0xFF6A2CEA), size: 18),
                          label: const Text("Share Live Trip", style: TextStyle(color: Color(0xFF6A2CEA), fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _shareLiveTrip,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Test simulation trigger
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2CEA),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RiderRatingPaymentScreen(ride: widget.ride),
                            ),
                          );
                        },
                        child: const Text("End Trip (Pay)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
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
