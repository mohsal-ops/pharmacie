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
  LatLng?             userLocation;
  final Set<Marker>   markers    = {};
  final List<Map<String, dynamic>> pharmacies = [];

  final TextEditingController searchController = TextEditingController();
  bool   searching    = false;
  List<Map<String, dynamic>> searchResults = [];
  bool   _showHistory = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    loadLocation();
    _loadSearchHistory();
  }

  // ── Load search history from Firestore ──────────────────────────────────
  Future<void> _loadSearchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final history = doc.data()?['searchHistory'] as List<dynamic>? ?? [];
    setState(() {
      _searchHistory = history.cast<String>().reversed.take(10).toList();
    });
  }

  // ── Save search term to Firestore ────────────────────────────────────────
  Future<void> _saveSearchTerm(String term) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || term.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'searchHistory': FieldValue.arrayUnion([term.trim()])
    }, SetOptions(merge: true));

    await _loadSearchHistory();
  }

  // ── Location ─────────────────────────────────────────────────────────────
  Future<void> loadLocation() async {
    Position pos = await LocationService.getUserLocation();
    setState(() {
      userLocation = LatLng(pos.latitude, pos.longitude);
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: userLocation!,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
      ));
    });
    fetchNearbyPharmacies();
  }

  void fetchNearbyPharmacies() async {
    final results = await GooglePlacesService.getNearbyPharmacies(
      userLocation!.latitude,
      userLocation!.longitude,
    );

    pharmacies.clear();
    markers.removeWhere((m) => m.markerId.value != 'me');

    for (var p in results) {
      double distance = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            p['lat'],
            p['lng'],
          ) /
          1000;

      pharmacies.add({...p, 'distance': distance});
      markers.add(Marker(
        markerId: MarkerId(p['placeId']),
        position: LatLng(p['lat'], p['lng']),
        infoWindow: InfoWindow(title: p['name']),
      ));
    }

    pharmacies.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));
    setState(() {});
  }

  // ── SEARCH — queries Firestore pharmacies collection ────────────────────
  Future<void> searchMedicine() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    // Hide history dropdown
    setState(() {
      searching    = true;
      searchResults.clear();
      _showHistory = false;
    });

    // Save to history
    await _saveSearchTerm(query);

    try {
      // Query ALL pharmacies
      final pharmaciesSnap = await FirebaseFirestore.instance
          .collection('pharmacies')
          .get();

      for (var pharmacyDoc in pharmaciesSnap.docs) {
        final pharmacyData = pharmacyDoc.data();
        final medicines =
            pharmacyData['medicines'] as List<dynamic>? ?? [];

        // Find medicines matching the search query (partial match)
        for (var med in medicines) {
          final medName = (med['name'] as String? ?? '').toLowerCase();
          if (medName.contains(query.toLowerCase())) {

            // Calculate distance if we have user location
            double distance = 0;
            if (userLocation != null &&
                pharmacyData['lat'] != null &&
                pharmacyData['lng'] != null) {
              distance = Geolocator.distanceBetween(
                    userLocation!.latitude,
                    userLocation!.longitude,
                    pharmacyData['lat'],
                    pharmacyData['lng'],
                  ) /
                  1000;
            }

            searchResults.add({
              'medicineName':    med['name'],
              'medicinePrice':   med['price'],
              'medicineAvailable': med['available'] ?? false,
              'pharmacyId':      pharmacyDoc.id,
              'pharmacyName':    pharmacyData['name'] ?? 'Pharmacy',
              'pharmacyAddress': pharmacyData['address'] ?? '',
              'pharmacyOpen':    pharmacyData['open'] ?? false,
              'distance':        distance,
              'lat':             pharmacyData['lat'] ?? 0.0,
              'lng':             pharmacyData['lng'] ?? 0.0,
            });
          }
        }
      }

      // Sort by distance
      searchResults.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

    } catch (e) {
      debugPrint('Search error: $e');
    }

    setState(() => searching = false);
  }

  Future<void> openDirections(double lat, double lng) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Find Medicines',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ClientProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
      body: Column(children: [

        // ── Search bar + history ────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onTap: () {
                    if (_searchHistory.isNotEmpty) {
                      setState(() => _showHistory = true);
                    }
                  },
                  onChanged: (v) {
                    if (v.isEmpty) {
                      setState(() {
                        searchResults.clear();
                        _showHistory = _searchHistory.isNotEmpty;
                      });
                    }
                  },
                  onSubmitted: (_) => searchMedicine(),
                  decoration: InputDecoration(
                    hintText: 'Search medicine (ex: paracetamol)',
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF0F9D58)),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchResults.clear();
                                _showHistory = false;
                              });
                            })
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                ),
                onPressed: searchMedicine,
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white),
              ),
            ]),

            // ── History dropdown ────────────────────────────────────────
            if (_showHistory && _searchHistory.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: _searchHistory.map((term) =>
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history,
                          color: Colors.grey, size: 18),
                      title: Text(term,
                          style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        searchController.text = term;
                        setState(() => _showHistory = false);
                        searchMedicine();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.north_west,
                            size: 14, color: Colors.grey),
                        onPressed: () {
                          searchController.text = term;
                          setState(() => _showHistory = false);
                        },
                      ),
                    ),
                  ).toList(),
                ),
              ),
          ]),
        ),

        // ── Map ─────────────────────────────────────────────────────────
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.30,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: userLocation!, zoom: 14),
                markers: markers,
                onMapCreated: (c) => mapController = c,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Results / Pharmacy list ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                searchResults.isNotEmpty
                    ? '${searchResults.length} result(s) found'
                    : 'Nearby Pharmacies',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (searchResults.isNotEmpty)
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchResults.clear());
                  },
                  child: const Text('Clear',
                      style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),

        Expanded(
          child: searching
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty && searchController.text.isNotEmpty
                  // No results found
                  ? _NoResults(query: searchController.text)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                      itemCount: searchResults.isNotEmpty
                          ? searchResults.length
                          : pharmacies.length,
                      itemBuilder: (context, i) {
                        if (searchResults.isNotEmpty) {
                          return _MedicineResultCard(
                            result: searchResults[i],
                            onDirections: openDirections,
                          );
                        } else {
                          return _PharmacyCard(
                            pharmacy: pharmacies[i],
                            onDirections: openDirections,
                          );
                        }
                      },
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Medicine search result card
// ─────────────────────────────────────────────────────────────────────────────
class _MedicineResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final Function(double, double) onDirections;
  const _MedicineResultCard(
      {required this.result, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final bool medAvailable  = result['medicineAvailable'] as bool;
    final bool pharmacyOpen  = result['pharmacyOpen'] as bool;
    final double distance    = result['distance'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [

        // ── Medicine info banner ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: medAvailable
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medication,
                  color: medAvailable
                      ? const Color(0xFF0F9D58)
                      : const Color(0xFFE53935),
                  size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['medicineName'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    medAvailable
                        ? 'In stock'
                        : 'Out of stock',
                    style: TextStyle(
                        fontSize: 13,
                        color: medAvailable
                            ? const Color(0xFF0F9D58)
                            : const Color(0xFFE53935),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result['medicinePrice']} DA',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F9D58)),
                ),
                const Text('per unit',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ]),
        ),

        // ── Pharmacy info ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.local_pharmacy,
                  color: Color(0xFF0F9D58), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['pharmacyName'],
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              _StatusChip(isOpen: pharmacyOpen),
            ]),

            const SizedBox(height: 8),

            Row(children: [
              const Icon(Icons.location_on,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  result['pharmacyAddress'].isNotEmpty
                      ? result['pharmacyAddress']
                      : '${distance.toStringAsFixed(2)} km away',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(children: [
                const Icon(Icons.directions_walk,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 2),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
              ]),
            ]),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => onDirections(
                    result['lat'], result['lng']),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nearby pharmacy card (shown before search)
// ─────────────────────────────────────────────────────────────────────────────
class _PharmacyCard extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  final Function(double, double) onDirections;
  const _PharmacyCard(
      {required this.pharmacy, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final bool open      = pharmacy['open'] as bool? ?? true;
    final double distance = pharmacy['distance'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_pharmacy,
                color: Color(0xFF0F9D58)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pharmacy['name'] ?? 'Pharmacy',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            _StatusChip(isOpen: open),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on,
                size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${distance.toStringAsFixed(2)} km away',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => onDirections(
                  pharmacy['lat'], pharmacy['lng']),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isOpen
                ? const Color(0xFF0F9D58)
                : const Color(0xFFE53935)),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            '"$query" not found',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'No pharmacy in the database has this medicine',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}