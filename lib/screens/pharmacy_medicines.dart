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
    var doc = FirebaseFirestore.instance.collection('pharmacies').doc(uid);
    await doc.set({
      'name': 'My Pharmacy', // For simplicity, replace with profile name
      'address': 'Address',  // Replace with profile address
      'medicines': FieldValue.arrayUnion([
        {
          'name': nameController.text,
          'price': int.parse(priceController.text),
          'available': available,
        }
      ])
    }, SetOptions(merge: true));
    nameController.clear();
    priceController.clear();
    setState(() {}); // refresh
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: 'Medicine Name')),
          TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price')),
          Row(
            children: [
              Checkbox(value: available, onChanged: (v) => setState(() => available = v!)),
              Text('Available'),
            ],
          ),
          ElevatedButton(onPressed: addMedicine, child: Text('Add Medicine')),
        ],
      ),
    );
  }
}
