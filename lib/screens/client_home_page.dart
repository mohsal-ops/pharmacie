import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/client_profile_page.dart';
import '../services/location_service.dart';
import '../services/google_places_service.dart';
import 'login_page.dart';

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

        searchResults.add({
          'name': data['name'],
          'price': data['price'],
          'pharmacyId': pharmacyId,
          'distance': distance,
          'lat': pharmacyMarker.position.latitude,
          'lng': pharmacyMarker.position.longitude,
          'open': true,
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

  Future<void> openDirections(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Find Medicines"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientProfilePage()),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
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
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search medicine (ex: paracetamol)",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: searchMedicine,
                ),
              ),
              onSubmitted: (_) => searchMedicine(),
            ),
          ),

          /// MAP
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: userLocation!,
                    zoom: 14,
                  ),
                  markers: markers,
                  onMapCreated: (c) => mapController = c,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// PHARMACY LIST
          Expanded(
            child: searching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: searchResults.isEmpty
                        ? pharmacies.length
                        : searchResults.length,
                    itemBuilder: (context, i) {
                      final p = searchResults.isEmpty
                          ? pharmacies[i]
                          : searchResults[i];

                      final bool open = p["open"] ?? true;

                      final double lat = p["lat"];
                      final double lng = p["lng"];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_pharmacy,
                                  color: Colors.teal,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    p["name"] ?? "Pharmacy",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: open
                                        ? Colors.green.withOpacity(.15)
                                        : Colors.red.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    open ? "OPEN" : "CLOSED",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: open ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${p["distance"].toStringAsFixed(2)} km away",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.directions),
                                label: const Text("Get Directions"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  openDirections(lat, lng);
                                },
                              ),
                            ),
                          ],
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
