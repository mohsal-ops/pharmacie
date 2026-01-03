import 'package:flutter/material.dart';
import '../services/location_service.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  String searchQuery = '';
  bool loadingLocation = true;

  // FAKE DATA (later from Firestore)
  final List<Map<String, dynamic>> pharmacies = [
    {
      'name': 'Pharmacie Centrale',
      'open': true,
      'medicines': ['doliprane', 'paracetamol']
    },
    {
      'name': 'Pharmacie El Amal',
      'open': false,
      'medicines': ['aspirine']
    },
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void _getLocation() async {
    try {
      await LocationService.getCurrentLocation();
    } catch (e) {
      print(e);
    }
    setState(() {
      loadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = pharmacies.where((pharmacy) {
      return pharmacy['medicines']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Find a medicine')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search medicine...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final pharmacy = results[index];
                return ListTile(
                  title: Text(pharmacy['name']),
                  subtitle: Text(
                    pharmacy['open'] ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: pharmacy['open']
                          ? Colors.green
                          : Colors.red,
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
