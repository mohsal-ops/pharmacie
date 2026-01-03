import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'client_search.dart'; // import search page

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  String searchQuery = '';
  bool loadingLocation = true;

  // FAKE DATA (later replace with Firestore)
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
      final position = await LocationService.getCurrentLocation();
      print('Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Location Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = pharmacies.where((pharmacy) {
      return (pharmacy['medicines'] as List<String>).any(
        (med) => med.toLowerCase().contains(searchQuery.toLowerCase()),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a medicine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientSearchPage()),
              );
            },
          )
        ],
      ),
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
                      color: pharmacy['open'] ? Colors.green : Colors.red,
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
