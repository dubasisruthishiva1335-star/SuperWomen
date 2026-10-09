import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/rider_ride_service.dart';
import '../services/rider_socket_service.dart';
import '../widgets/google_map_widget.dart';
import 'live_tracking_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String selectedVehicle = 'bike';
  bool _isSearching = false;
  Map<String, dynamic>? _currentRide;
  final RiderSocketService _socketService = RiderSocketService();

  final TextEditingController _pickupController = TextEditingController(text: "Koramangala 80ft Rd, Bangalore");
  final TextEditingController _dropController = TextEditingController(text: "Indiranagar Metro Station");

  @override
  void initState() {
    super.initState();
    _socketService.connect();

    _socketService.onCaptainAssigned = (rideData) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _currentRide = rideData;
        });
        _showCaptainAssignedDialog(rideData);
      }
    };
  }

  Future<void> _startRideBooking() async {
    setState(() => _isSearching = true);

    try {
      // 1. Send request to backend
      final ride = await RiderRideService.requestRide(
        pickupLat: 12.9716,
        pickupLng: 77.5946,
        dropLat: 12.9784,
        dropLng: 77.6408,
      );

      _currentRide = ride;
      _socketService.joinRideRoom(ride['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF6A2CEA),
            content: Text("📡 Searching for nearby SuperWomen Captains..."),
          ),
        );
      }
    } catch (e) {
      // If offline/backend mock fallback
      _currentRide = {
        'id': 'simulated-ride-${DateTime.now().millisecondsSinceEpoch}',
        'fare': selectedVehicle == 'bike' ? 185.0 : 240.0,
        'otp': '4972',
      };
    }
  }

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
                    subtitle: "Fastest · 2 min away",
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
                    subtitle: "Comfort · 4 min away",
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
                        _startRideBooking();
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

  void _showCaptainAssignedDialog(Map<String, dynamic> ride) {
    final otp = ride['otp'] ?? _currentRide?['otp'] ?? '4972';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("👩✈️ Captain Assigned!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Captain Priya Sharma is on the way (Honda Activa 6G · KA01 SW 1234)."),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBFF),
                border: Border.all(color: const Color(0xFF6A2CEA)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text("Share this OTP with Captain to Start:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6A2CEA))),
                    const SizedBox(height: 4),
                    Text(
                      otp.split('').join(' '),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF6A2CEA), letterSpacing: 4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A2CEA)),
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiderLiveTrackingScreen(ride: ride),
                ),
              );
            },
            child: const Text("Track Captain Live →", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF635777))),
                  ],
                ),
              ],
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF6A2CEA))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Interactive Google Map View
          const GoogleMapWidget(
            initialCenter: LatLng(12.9716, 77.5946),
            initialZoom: 14.5,
            pickupLocation: LatLng(12.9352, 77.6245), // Koramangala 80ft Rd
            dropLocation: LatLng(12.9784, 77.6408), // Indiranagar Metro
            vehicleLocation: LatLng(12.9480, 77.6180), // Nearby SuperWomen Captain
            vehicleType: 'BIKE',
          ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Row(
                      children: [
                        Text("🛡️", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text("100% Women-Safe Rides", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6A2CEA))),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.person, color: Color(0xFF6A2CEA)),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Searching Pulsing Card (When ride is dispatched)
          if (_isSearching) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF13072E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFE91E63)),
                    const SizedBox(height: 16),
                    const Text(
                      "Finding Nearby Captains...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Connecting with nearby women drivers on 80ft Road",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
                            onPressed: () => setState(() => _isSearching = false),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Test instant simulate accept
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A2CEA)),
                            onPressed: () {
                              setState(() => _isSearching = false);
                              _showCaptainAssignedDialog({
                                'id': _currentRide?['id'] ?? 'mock-ride',
                                'otp': '4972',
                                'fare': 185.0,
                              });
                            },
                            child: const Text("Simulate Accept", style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom Search Card
          if (!_isSearching) ...[
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pickup input
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF00C853), size: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pickupController,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Drop input
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFFFF334B), size: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _dropController,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2CEA),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _showBookingSheet,
                        child: const Text("Choose SuperRide (From ₹50) 🛵", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
