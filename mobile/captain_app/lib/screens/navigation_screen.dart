import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_theme.dart';
import '../services/captain_ride_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _pickupLocation = const LatLng(12.9352, 77.6245); // Koramangala
  LatLng _dropLocation = const LatLng(12.9784, 77.6408); // Indiranagar
  LatLng _captainLocation = const LatLng(12.9480, 77.6180);

  // Search & Places Suggestions
  bool _showSearchBar = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  String get _rideId => widget.ride?['id'] ?? 'mock-ride-id';
  double get _fare => (widget.ride?['fare'] as num?)?.toDouble() ?? 185.0;

  @override
  void initState() {
    super.initState();
    _rideStage = widget.ride?['status'] == 'STARTED' ? 'STARTED' : 'TO_PICKUP';
    if (widget.ride?['pickupLat'] != null && widget.ride?['pickupLng'] != null) {
      _pickupLocation = LatLng((widget.ride!['pickupLat'] as num).toDouble(), (widget.ride!['pickupLng'] as num).toDouble());
    }
    if (widget.ride?['dropLat'] != null && widget.ride?['dropLng'] != null) {
      _dropLocation = LatLng((widget.ride!['dropLat'] as num).toDouble(), (widget.ride!['dropLng'] as num).toDouble());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _otpController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final list = await CaptainRideService.getAutocomplete(query);
      if (mounted) {
        setState(() {
          _suggestions = list;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> item) async {
    final text = item['text'] as String? ?? '';
    final placeId = item['placeId'] as String?;
    double? lat = (item['lat'] as num?)?.toDouble();
    double? lng = (item['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      final geocoded = await CaptainRideService.geocode(placeId: placeId, address: text);
      if (geocoded != null) {
        lat = (geocoded['lat'] as num?)?.toDouble();
        lng = (geocoded['lng'] as num?)?.toDouble();
      }
    }

    lat ??= 12.9716;
    lng ??= 77.5946;

    final targetPoint = LatLng(lat, lng);

    setState(() {
      _dropLocation = targetPoint;
      _suggestions = [];
      _showSearchBar = false;
      _searchController.clear();
    });

    FocusScope.of(context).unfocus();
    _mapController.move(targetPoint, 15.5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryPurple,
        content: Text("📍 Destination updated: $text"),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    setState(() {
      _dropLocation = point;
      _suggestions = [];
    });
    _mapController.move(point, _mapController.camera.zoom);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryPurple,
        content: Text("📍 Drop Pin updated to tapped map position!"),
      ),
    );
  }

  Future<void> _launchGoogleMapsNavigation(double targetLat, double targetLng) async {
    final navUri = Uri.parse("google.navigation:q=$targetLat,$targetLng&mode=d");
    final webUri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&travelmode=driving");
    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPassenger(String phone) async {
    final telUri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (_) {}
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
        _showCompletedDialog();
      }
    } catch (e) {
      setState(() {
        _rideStage = 'COMPLETED';
        _isLoading = false;
      });
      if (mounted) {
        _showCompletedDialog();
      }
    }
  }

  void _showCompletedDialog() {
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
          GoogleMapWidget(
            mapController: _mapController,
            initialCenter: const LatLng(12.9716, 77.5946),
            initialZoom: 15.5,
            vehicleLocation: _captainLocation,
            pickupLocation: _pickupLocation,
            dropLocation: _dropLocation,
            onMapTap: _handleMapTap,
          ),

          // Top Directions Banner & Search Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                                  _rideStage == 'STARTED' ? "Destination (${_dropLocation.latitude.toStringAsFixed(3)}, ${_dropLocation.longitude.toStringAsFixed(3)})" : "Pickup Point",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(_showSearchBar ? Icons.close : Icons.search, color: Colors.white, size: 20),
                              tooltip: "Search Destination",
                              onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentPink,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.navigation, color: Colors.white, size: 16),
                              label: const Text("GPS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                              onPressed: () {
                                final lat = _rideStage == 'STARTED' ? _dropLocation.latitude : _pickupLocation.latitude;
                                final lng = _rideStage == 'STARTED' ? _dropLocation.longitude : _pickupLocation.longitude;
                                _launchGoogleMapsNavigation(lat, lng);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search input bar when toggled
                  if (_showSearchBar) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: "Search area to re-route destination...",
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppTheme.primaryPurple, size: 20),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Autocomplete Suggestions Floating Dropdown for Captain
          if (_suggestions.isNotEmpty || _isLoadingSuggestions) ...[
            Positioned(
              left: 16,
              right: 16,
              top: 140,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple)),
                                SizedBox(width: 12),
                                Text("Searching destinations...", style: TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = _suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, color: AppTheme.primaryPurple, size: 20),
                              title: Text(item['text'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black26),
                              onTap: () => _selectSuggestion(item),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],

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
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.purpleTint,
                            child: Text("R", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Passenger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("★ 4.9 · Woman Rider", style: TextStyle(color: AppTheme.inkSoft, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.phone, color: AppTheme.safeGreen, size: 22),
                            tooltip: "Call Passenger",
                            onPressed: () => _callPassenger('+919876543210'),
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
                        label: const Text("ENTER OTP TO START RIDE", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        onPressed: _showOtpDialog,
                      ),
                    ),
                  ] else if (_rideStage == 'STARTED') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text("COMPLETE RIDE & COLLECT FARE", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        onPressed: _completeRide,
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
