import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ← add this
import '../services/location_service.dart';
import '../services/google_places_service.dart';
import 'login_page.dart'; // ← add this

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

  final TextEditingController searchController = TextEditingController();
  bool searching = false;
  List<Map<String, dynamic>> searchResults = [];

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

  Future<void> searchMedicine() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      searching = true;
      searchResults.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('medicines')
          .where('available', isEqualTo: true)
          .where('name', isEqualTo: query)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final pharmacyId = doc.reference.parent.parent!.id;

        // Find marker for this pharmacy
        final pharmacyMarker = markers.firstWhere(
          (m) => m.markerId.value == pharmacyId,
          orElse: () =>
              Marker(markerId: MarkerId(pharmacyId), position: LatLng(0, 0)),
        );

        final distance =
            Geolocator.distanceBetween(
              userLocation!.latitude,
              userLocation!.longitude,
              pharmacyMarker.position.latitude,
              pharmacyMarker.position.longitude,
            ) /
            1000;

        // Find open status from nearby pharmacies list if exists
        final openStatus = pharmacies.firstWhere(
          (p) => p["placeId"] == pharmacyId,
          orElse: () => {"open": false},
        )["open"];

        searchResults.add({
          'name': data['name'],
          'price': data['price'],
          'pharmacyId': pharmacyId,
          'distance': distance,
          'lat': pharmacyMarker.position.latitude,
          'lng': pharmacyMarker.position.longitude,
          'open': openStatus,
        });
      }

      searchResults.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );
    } catch (e) {
      debugPrint('Search error: $e');
    }

    setState(() {
      searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Pharmacies"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search medicine...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchMedicine,
                ),
              ),
              onSubmitted: (_) => searchMedicine(),
            ),
          ),

          // 🗺 Map
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

          // 📋 Results list
          Expanded(
            child: searching
                ? const Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                ? ListView.builder(
                    itemCount: pharmacies.length,
                    itemBuilder: (_, i) {
                      final p = pharmacies[i];
                      return ListTile(
                        leading: const Icon(Icons.local_pharmacy),
                        title: Text(p["name"]),
                        subtitle: Text(
                          "${p["distance"].toStringAsFixed(2)} km away",
                        ),
                        trailing: Text(
                          p["open"] ? "Open" : "Closed",
                          style: TextStyle(
                            color: p["open"] ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, i) {
                      final p = searchResults[i];
                      return ListTile(
                        leading: const Icon(Icons.local_pharmacy),
                        title: Text(p['pharmacyId']),
                        subtitle: Text(
                          "${p['distance'].toStringAsFixed(2)} km away",
                        ),
                        trailing: Text(
                          p['open'] ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: p['open'] ? Colors.green : Colors.red,
                          ),
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
