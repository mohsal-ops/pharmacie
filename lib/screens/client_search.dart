import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientSearchPage extends StatefulWidget {
  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> results = [];

  void searchMedicine() async {
    String query = searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> temp = [];
    var pharmacies = await FirebaseFirestore.instance.collection('pharmacies').get();
    for (var doc in pharmacies.docs) {
      List medicines = doc['medicines'] ?? [];
      for (var med in medicines) {
        if ((med['name'] as String).toLowerCase() == query && med['available'] == true) {
          temp.add({
            'pharmacy': doc['name'],
            'address': doc['address'],
            'medicine': med['name'],
            'price': med['price'],
          });
        }
      }
    }
    setState(() {
      results = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: searchController, decoration: InputDecoration(labelText: 'Medicine name')),
          ElevatedButton(onPressed: searchMedicine, child: Text('Search')),
          Expanded(
            child: ListView.builder(
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
    );
  }
}
