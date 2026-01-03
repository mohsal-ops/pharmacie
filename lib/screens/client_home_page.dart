import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/google_places_service.dart';
import 'package:location/location.dart';
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

  String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}


  @override
  void initState() {
    super.initState();
    _initLocationAndPharmacies();
  }

  Future<void> _initLocationAndPharmacies() async {
    try {
      // Get LocationData from LocationService
      LocationData? locationData = await LocationService.getCurrentLocation();

      if (locationData == null || locationData.latitude == null || locationData.longitude == null) {
        throw Exception('Unable to get current location');
      }

      // Convert LocationData to Position
      userLocation = Position(
  latitude: locationData.latitude!,
  longitude: locationData.longitude!,
  timestamp: DateTime.now(),
  accuracy: locationData.accuracy ?? 0.0,
  altitude: locationData.altitude ?? 0.0,
  altitudeAccuracy: 0.0,       // <- add this
  heading: locationData.heading ?? 0.0,
  headingAccuracy: 0.0,        // <- add this
  speed: locationData.speed ?? 0.0,
  speedAccuracy: 0.0,
);

      // Fetch nearby pharmacies
      pharmacies = await GooglePlacesService.getNearbyPharmacies(
        userLocation!.latitude,
        userLocation!.longitude,
      );

      _updateMarkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _updateMarkers() {
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

    setState(() {});
  }

  List<Map<String, dynamic>> get filteredPharmacies {
    final withDistance = pharmaciesWithDistance;
    if (searchQuery.isEmpty) return withDistance;
    return withDistance.where((pharmacy) {
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // distance in meters
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search medicine...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value;
                _updateMarkers();
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

          const SizedBox(height: 8.0),

          // List of pharmacies
          Expanded(
            child: ListView.builder(
              itemCount: filteredPharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = filteredPharmacies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(pharmacy['name']),
                    subtitle:  Text(
  '${formatDistance(pharmacy['distance'])} • '
  '${pharmacy['open'] ? 'Open now' : 'Closed'}',
),

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
