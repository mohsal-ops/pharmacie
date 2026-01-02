import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_search.dart';
import 'pharmacy_medicines.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String role = '';
  String name = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        role = doc['role'] ?? '';
        name = doc['name'] ?? '';
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $name'),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: logout)],
      ),
      body: Center(
        child: role == 'client'
            ? ClientSearchPage()
            : PharmacyMedicinesPage(),
      ),
    );
  }
}
