import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/google_places_service.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  GoogleMapController? mapController;
  LatLng? userLocation;
  final Set<Marker> markers = {};
  final List<Map<String, dynamic>> pharmacies = [];

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    Position pos = await LocationService.getUserLocation();

    setState(() {
      userLocation = LatLng(pos.latitude, pos.longitude);
      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: userLocation!,
          infoWindow: const InfoWindow(title: "You"),
        ),
      );
    });

    fetchNearbyPharmacies();
  }

  void fetchNearbyPharmacies() async {
    final results = await GooglePlacesService.getNearbyPharmacies(
      userLocation!.latitude,
      userLocation!.longitude,
    );

    print(results);
    pharmacies.clear();
    markers.clear();

    markers.add(
      Marker(
        markerId: const MarkerId("me"),
        position: userLocation!,
        infoWindow: const InfoWindow(title: "You"),
      ),
    );

    for (var p in results) {
      double distance =
          Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            p["lat"],
            p["lng"],
          ) /
          1000;

      pharmacies.add({...p, "distance": distance});

      markers.add(
        Marker(
          markerId: MarkerId(p["placeId"]),
          position: LatLng(p["lat"], p["lng"]),
          infoWindow: InfoWindow(title: p["name"]),
        ),
      );
    }

    pharmacies.sort(
      (a, b) => (a["distance"] as double).compareTo(b["distance"] as double),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Pharmacies")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLocation!,
                zoom: 14,
              ),
              markers: markers,
              onMapCreated: (c) => mapController = c,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pharmacies.length,
              itemBuilder: (_, i) {
                final p = pharmacies[i];
                return ListTile(
                  leading: const Icon(Icons.local_pharmacy),
                  title: Text(p["name"]),
                  subtitle: Text("${p["distance"]} km away"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
