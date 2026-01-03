import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientSearchPage extends StatefulWidget {
  const ClientSearchPage({super.key});

  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  void searchMedicine(String query) async {
    if (query.isEmpty) {
      setState(() {
        results = [];
      });
      return;
    }

    setState(() {
      loading = true;
    });

    query = query.trim().toLowerCase();
    List<Map<String, dynamic>> temp = [];
    try {
      var pharmacies = await FirebaseFirestore.instance.collection('pharmacies').get();
      for (var doc in pharmacies.docs) {
        List medicines = doc['medicines'] ?? [];
        for (var med in medicines) {
          final medName = (med['name'] ?? '').toString().toLowerCase();
          final available = med['available'] ?? false;
          if (medName.contains(query) && available == true) {
            temp.add({
              'pharmacy': doc['name'] ?? '',
              'address': doc['address'] ?? '',
              'medicine': med['name'] ?? '',
              'price': med['price'] ?? 0,
            });
          }
        }
      }
    } catch (e) {
      print('Firestore error: $e');
    }

    setState(() {
      results = temp;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                border: OutlineInputBorder(),
              ),
              onChanged: searchMedicine, // search as user types
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        var r = results[index];
                        return ListTile(
                          title: Text(r['medicine']),
                          subtitle: Text('${r['pharmacy']} - ${r['address']}'),
                          trailing: Text('${r['price']} DA'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
