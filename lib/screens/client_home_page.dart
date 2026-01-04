import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';


class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  Position? userLocation;
  bool loading = true;
  String searchQuery = '';
  Set<Marker> markers = {};
  late GoogleMapController mapController;

  // Fake pharmacy data for testing
  List<Map<String, dynamic>> pharmacies = [
    {
      'name': 'Pharmacy El-Amal',
      'address': '123 Main Street',
      'lat': 36.7538,
      'lng': 3.0588,
      'workingHours': {'start': '08:00', 'end': '20:00'},
    },
    {
      'name': 'Pharmacy Santé',
      'address': '456 Center Road',
      'lat': 36.7560,
      'lng': 3.0620,
      'workingHours': {'start': '09:00', 'end': '18:00'},
    },
    {
      'name': 'Pharmacy Horizon',
      'address': '789 City Ave',
      'lat': 36.7540,
      'lng': 3.0550,
      'workingHours': {'start': '07:30', 'end': '21:00'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => loading = true);

    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      userLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Add marker for user location
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(userLocation!.latitude, userLocation!.longitude),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));

      // Add markers for pharmacies
      _updatePharmacyMarkers();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  void _updatePharmacyMarkers() {
    for (var pharmacy in pharmacies) {
      final open = _isPharmacyOpen(pharmacy['workingHours']);
      pharmacy['open'] = open;
      pharmacy['distance'] = _calculateDistance(
        userLocation!.latitude,
        userLocation!.longitude,
        pharmacy['lat'],
        pharmacy['lng'],
      );

      markers.add(Marker(
        markerId: MarkerId(pharmacy['name']),
        position: LatLng(pharmacy['lat'], pharmacy['lng']),
        infoWindow: InfoWindow(
          title: pharmacy['name'],
          snippet: open ? 'Open' : 'Closed',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            open ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
      ));
    }
  }

  bool _isPharmacyOpen(Map<String, String> hours) {
    final now = DateTime.now();
    final start = DateFormat('HH:mm').parse(hours['start']!);
    final end = DateFormat('HH:mm').parse(hours['end']!);

    final startTime =
        DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endTime =
        DateTime(now.year, now.month, now.day, end.hour, end.minute);

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    if (loading || userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredPharmacies = searchQuery.isEmpty
        ? pharmacies
        : pharmacies
            .where((p) => p['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Pharmacies')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search pharmacy...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          // Small map with user location
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                  target:
                      LatLng(userLocation!.latitude, userLocation!.longitude),
                  zoom: 14),
              myLocationEnabled: true,
              markers: markers
                  .where((m) => m.markerId.value == 'user_location')
                  .toSet(),
              onMapCreated: (controller) => mapController = controller,
            ),
          ),

          const SizedBox(height: 8.0),

          // List of pharmacies
          Expanded(
            child: ListView.builder(
              itemCount: filteredPharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = filteredPharmacies[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(pharmacy['name']),
                    subtitle: Text(
                        '${pharmacy['address']} • ${formatDistance(pharmacy['distance'])} • ${pharmacy['open'] ? 'Open now' : 'Closed'}'),
                    trailing: Icon(
                      pharmacy['open'] ? Icons.check_circle : Icons.cancel,
                      color: pharmacy['open'] ? Colors.green : Colors.red,
                    ),
                    onTap: () {
                      mapController.animateCamera(
                        CameraUpdate.newLatLng(
                            LatLng(pharmacy['lat'], pharmacy['lng'])),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
