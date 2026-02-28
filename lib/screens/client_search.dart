import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientSearchPage extends StatefulWidget {
  const ClientSearchPage({Key? key}) : super(key: key);

  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final TextEditingController controller = TextEditingController();

  bool loading = false;
  List<Map<String, dynamic>> results = [];

  Future<void> searchMedicines() async {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      results.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('medicines')
          .where('available', isEqualTo: true)
          .where('name', isEqualTo: controller.text.trim())
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final medicineName = data['name'].toString().toLowerCase();
        final searchText = controller.text.toLowerCase();

        if (medicineName.contains(searchText)) {
          results.add({
            'name': data['name'],
            'price': data['price'],
            'pharmacyId': doc.reference.parent.parent!.id,
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Medicine'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH INPUT
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 12),

            // 🔘 SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : searchMedicines,
                child: const Text('Search'),
              ),
            ),

            const SizedBox(height: 20),

            // ⏳ LOADING
            if (loading) const CircularProgressIndicator(),

            // 📋 RESULTS
            Expanded(
              child: results.isEmpty && !loading
                  ? const Center(
                      child: Text(
                        'No medicines found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final m = results[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.medication),
                            title: Text(m['name']),
                            subtitle: Text('Pharmacy ID: ${m["pharmacyId"]}'),
                            trailing: Text(
                              '${m["price"]} DA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
