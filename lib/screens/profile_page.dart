import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home_page.dart';
import 'pharmacy_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        role = 'client'; // fallback if not logged in
        loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Check if doc exists and has role field
      if (doc.exists && doc.data()?['role'] != null) {
        role = doc.data()!['role'] as String;
      } else {
        // If missing, default to client OR create role automatically
        role = 'client';

        // Optional: auto-create a role in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': role,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error loading role: $e');
      role = 'client';
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (role == 'client') {
      return const ClientHomePage();
    } else if (role == 'pharmacy') {
      return const PharmacyDashboard();
    } else {
      return const Scaffold(
        body: Center(child: Text('Unknown role, please contact support')),
      );
    }
  }
}