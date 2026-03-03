import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacyMedicinesPage extends StatefulWidget {
  const PharmacyMedicinesPage({super.key});

  @override
  State<PharmacyMedicinesPage> createState() => _PharmacyMedicinesPageState();
}

class _PharmacyMedicinesPageState extends State<PharmacyMedicinesPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  bool available = true;

  void addMedicine() async {
    final medicine = {
      'name': nameController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'available': available,
    };

    final docRef = FirebaseFirestore.instance.collection('pharmacies').doc(uid);

    // Add medicine to the medicines array
    await docRef.update({
      'medicines': FieldValue.arrayUnion([medicine]),
    });

    nameController.clear();
    priceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medicine added successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Medicine Name'),
          ),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          Row(
            children: [
              Checkbox(
                value: available,
                onChanged: (v) => setState(() => available = v!),
              ),
              const Text('Available'),
            ],
          ),
          ElevatedButton(onPressed: addMedicine, child: const Text('Add Medicine')),
        ],
      ),
    );
  }
}