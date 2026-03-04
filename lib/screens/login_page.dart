import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
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
  final locationController = TextEditingController();
  final FocusNode locationFocus = FocusNode();

  String role = 'client';
  bool isLogin = true;
  bool isLoading = false;

  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;
  String? selectedName;

  final String googleApiKey = "AIzaSyBHC2bxtnX78DbnetLdQ_ZEAIxEZsDT_9M";

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      UserCredential cred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final userRole = doc.data()?['role'];

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => userRole == 'client'
              ? const ClientHomePage()
              : const PharmacyDashboard(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed")),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> signup() async {
    if (role == 'pharmacy' &&
        (selectedLat == null || selectedLng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select pharmacy location")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
        'createdAt': Timestamp.now(),
      });

      if (role == 'pharmacy') {
        await FirebaseFirestore.instance.collection('pharmacies').doc(uid).set({
          'name': selectedName,
          'ownerEmail': emailController.text.trim(),
          'address': selectedAddress,
          'lat': selectedLat,
          'lng': selectedLng,
          'open': false,
          'medicines': [],
          'createdAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      setState(() => isLogin = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup failed")),
      );
    }

    setState(() => isLoading = false);
  }

 Widget buildInput({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool obscure = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1.4,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF0F9D58),
            width: 2,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F9D58),
              Color(0xFF34A853),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black12,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(Icons.local_pharmacy,
                        size: 60, color: Color(0xFF0F9D58)),

                    const SizedBox(height: 12),

                    const Text(
                      "MediFind",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    buildInput(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email_outlined,
                    ),

                    buildInput(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),

                    if (!isLogin) ...[
                      const SizedBox(height: 10),

                      ToggleButtons(
                        borderRadius: BorderRadius.circular(14),
                        isSelected: [
                          role == 'client',
                          role == 'pharmacy',
                        ],
                        onPressed: (index) {
                          setState(() {
                            role =
                                index == 0 ? 'client' : 'pharmacy';
                          });
                        },
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text("Client"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text("Pharmacy"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],

                    if (!isLogin && role == 'pharmacy')
                      GooglePlaceAutoCompleteTextField(
                        textEditingController: locationController,
                        focusNode: locationFocus,
                        googleAPIKey: googleApiKey,
                        inputDecoration: InputDecoration(
                          hintText: "Search your pharmacy",
                          prefixIcon:
                              const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        debounceTime: 800,
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng: (prediction) {
                          selectedLat =
                              double.parse(prediction.lat ?? "0");
                          selectedLng =
                              double.parse(prediction.lng ?? "0");
                        },
                        itemClick: (prediction) {
                          locationController.text =
                              prediction.description ?? "";
                          locationFocus.requestFocus();
                          selectedAddress = prediction.description;
                          selectedName = prediction
                              .structuredFormatting?.mainText;
                        },
                      ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        onPressed:
                            isLoading ? null : (isLogin ? login : signup),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                isLogin ? "Login" : "Create Account",
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () =>
                          setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "Create an account"
                            : "Already have an account?",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}