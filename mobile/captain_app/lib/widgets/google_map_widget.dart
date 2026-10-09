import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GoogleMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final LatLng? vehicleLocation;
  final List<LatLng>? routePoints;
  final String? vehicleType;
  final bool showTraffic;
  final VoidCallback? onRecenter;
  final void Function(LatLng)? onMapTap;
  final MapController? mapController;

  const GoogleMapWidget({
    super.key,
    this.initialCenter = const LatLng(12.9716, 77.5946), // Bangalore Central
    this.initialZoom = 15.0,
    this.pickupLocation,
    this.dropLocation,
    this.vehicleLocation,
    this.routePoints,
    this.vehicleType = 'BIKE',
    this.showTraffic = false,
    this.onRecenter,
    this.onMapTap,
    this.mapController,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  void _recenter() {
    final target = widget.vehicleLocation ?? widget.pickupLocation ?? widget.initialCenter;
    _mapController.move(target, 15.5);
    if (widget.onRecenter != null) widget.onRecenter!();
  }

  @override
  void didUpdateWidget(covariant GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vehicleLocation != null && widget.vehicleLocation != oldWidget.vehicleLocation) {
      _mapController.move(widget.vehicleLocation!, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.routePoints ?? _generateSampleRoute();
    final markers = <Marker>[];

    // Pickup Marker
    if (widget.pickupLocation != null) {
      markers.add(
        Marker(
          point: widget.pickupLocation!,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text('PICKUP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.location_on, color: Color(0xFF00C853), size: 28),
            ],
          ),
        ),
      );
    }

    // Drop Marker
    if (widget.dropLocation != null) {
      markers.add(
        Marker(
          point: widget.dropLocation!,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF334B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text('DROP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.location_on, color: Color(0xFFFF334B), size: 28),
            ],
          ),
        ),
      );
    }

    // Captain Vehicle Marker
    if (widget.vehicleLocation != null) {
      markers.add(
        Marker(
          point: widget.vehicleLocation!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6A2CEA).withOpacity(0.25),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6A2CEA),
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.navigation, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.vehicleLocation ?? widget.pickupLocation ?? widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 4,
            maxZoom: 18,
            onTap: (tapPosition, point) {
              if (widget.onMapTap != null) {
                widget.onMapTap!(point);
              }
            },
          ),
          children: [
            // Google Maps Roadmap Tiles
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.superwomen.captain',
            ),
            if (points.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: const Color(0xFF6A2CEA),
                    strokeWidth: 5.0,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Google Watermark Branding
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                const SizedBox(width: 4),
                Text('Maps', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.blue.shade700)),
              ],
            ),
          ),
        ),

        // Recenter Floating Button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'map_recenter_${DateTime.now().microsecondsSinceEpoch}',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6A2CEA),
            elevation: 4,
            onPressed: _recenter,
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      ],
    );
  }

  List<LatLng> _generateSampleRoute() {
    if (widget.pickupLocation == null || widget.dropLocation == null) return [];
    final p = widget.pickupLocation!;
    final d = widget.dropLocation!;
    final midLat = (p.latitude + d.latitude) / 2 + 0.002;
    final midLng = (p.longitude + d.longitude) / 2 + 0.003;
    return [
      p,
      LatLng((p.latitude + midLat) / 2, (p.longitude + midLng) / 2),
      LatLng(midLat, midLng),
      LatLng((midLat + d.latitude) / 2, (midLng + d.longitude) / 2),
      d,
    ];
  }
}
