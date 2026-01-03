import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  Position? userLocation;
  bool loading = true;
  String searchQuery = '';
  List<Map<String, dynamic>> pharmacies = [];
  Set<Marker> markers = {};
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _initLocationAndPharmacies();
  }

  Future<void> _initLocationAndPharmacies() async {
    try {
      // 1️⃣ Get user location
      userLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2️⃣ Fetch pharmacies from Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .get();

      pharmacies = snapshot.docs.map((doc) {
        final data = doc.data();
        data['lat'] = (data['lat'] ?? 0).toDouble();
        data['lng'] = (data['lng'] ?? 0).toDouble();
        return data;
      }).toList();

      _updateMarkers();
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _updateMarkers() {
    // Filter by search query
    final filtered = filteredPharmacies;
    markers = filtered.map((pharmacy) {
      return Marker(
        markerId: MarkerId(pharmacy['name']),
        position: LatLng(pharmacy['lat'], pharmacy['lng']),
        infoWindow: InfoWindow(
            title: pharmacy['name'],
            snippet: pharmacy['open'] ? 'Open' : 'Closed'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            pharmacy['open'] ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
      );
    }).toSet();
  }

  List<Map<String, dynamic>> get filteredPharmacies {
    if (searchQuery.isEmpty) return pharmaciesWithDistance;
    return pharmaciesWithDistance.where((pharmacy) {
      final medicines = pharmacy['medicines'] as List<dynamic>;
      return medicines.any((med) =>
          med['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
  }

  List<Map<String, dynamic>> get pharmaciesWithDistance {
    if (userLocation == null) return [];
    return pharmacies.map((pharmacy) {
      final distance = _calculateDistance(
        userLocation!.latitude,
        userLocation!.longitude,
        pharmacy['lat'],
        pharmacy['lng'],
      );
      pharmacy['distance'] = distance; // meters
      return pharmacy;
    }).toList()
      ..sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Approximate distance in meters (Haversine)
    const p = 0.017453292519943295; // pi /180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2*R*asin
  }

  @override
  Widget build(BuildContext context) {
    if (loading || userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Pharmacies')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search medicine...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _updateMarkers();
                });
              },
            ),
          ),

          // Map
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(userLocation!.latitude, userLocation!.longitude),
                zoom: 14,
              ),
              myLocationEnabled: true,
              markers: markers,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),

          const SizedBox(height: 8),

          // List of pharmacies
          Expanded(
            child: ListView.builder(
              itemCount: filteredPharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = filteredPharmacies[index];
                return ListTile(
                  title: Text(pharmacy['name']),
                  subtitle: Text(
                      '${pharmacy['distance'].toStringAsFixed(0)} m away - ${pharmacy['open'] ? 'Open' : 'Closed'}'),
                  trailing: Icon(
                    pharmacy['open'] ? Icons.check_circle : Icons.cancel,
                    color: pharmacy['open'] ? Colors.green : Colors.red,
                  ),
                  onTap: () {
                    // Move map to marker
                    mapController.animateCamera(CameraUpdate.newLatLng(
                        LatLng(pharmacy['lat'], pharmacy['lng'])));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
