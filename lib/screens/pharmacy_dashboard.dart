import 'package:flutter/material.dart';
import 'pharmacy_medicines.dart';

class PharmacyDashboard extends StatelessWidget {
  const PharmacyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pharmacy Dashboard")),
      body: const PharmacyMedicinesPage(),
    );
  }
}