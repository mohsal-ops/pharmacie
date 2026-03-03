import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home_page.dart';
import 'pharmacy_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String role = 'client';
  bool isLogin = true;

  Future<void> login() async {
    try {
      // Sign in
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      // Fetch role from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userRole = doc.data()?['role'];

      if (userRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Role not found in database.")),
        );
        return;
      }

      // Navigate based on role
      if (userRole == 'client') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ClientHomePage()));
      } else if (userRole == 'pharmacy') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const PharmacyDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown role.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Auth error")),
      );
    }
  }

  Future<void> signup() async {
    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      // Always create user document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
        'createdAt': Timestamp.now(),
      });

      // If pharmacy, also create pharmacy document with full structure
      if (role == 'pharmacy') {
        await FirebaseFirestore.instance.collection('pharmacies').doc(uid).set({
          'name': 'New Pharmacy', // you can add input field later
          'ownerEmail': emailController.text.trim(),
          'address': '',
          'lat': 0.0,
          'lng': 0.0,
          'open': false,
          'medicines': [],
          'createdAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Auth error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),

            if (!isLogin)
              DropdownButton<String>(
                value: role,
                items: ['client', 'pharmacy']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => role = val!),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLogin ? login : signup,
              child: Text(isLogin ? 'Login' : 'Signup'),
            ),

            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Create account' : 'Already have account?'),
            )
          ],
        ),
      ),
    );
  }
}