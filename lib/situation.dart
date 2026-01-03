import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacie/Add_information_client.dart';
import 'package:pharmacie/add_information_pharmacy.dart';

class Situation extends StatelessWidget {
  const Situation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      //  theme: ThemeData(primarySwatch: Colors.indigo),
      home: Situation2(),
    );
  }
}

class Situation2 extends StatefulWidget {
  const Situation2({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Situation2> {
  final auth = FirebaseAuth.instance;
  String n = "U";
  String xx = '';

  int _selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[50],
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Text(
                "Hello, ",
                style: GoogleFonts.aBeeZee(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: CircleAvatar(
              backgroundColor: Colors.indigo[100],
              child: Text(
                "Abir",
                style: GoogleFonts.aBeeZee(
                  color: const Color.fromARGB(255, 23, 20, 49),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yassir Cash Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(blurRadius: 2, color: Colors.indigo)],
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(
                            "choise your situation",
                            style: GoogleFonts.aBeeZee(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(blurRadius: 5, color: Colors.indigo),
                        ],
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Ride Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Add_information_pharmacy(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(blurRadius: 5, color: Colors.indigo),
                          ],
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width / 3,
                              ),
                            ),
                            Icon(
                              Icons.local_pharmacy_outlined,
                              size: 40,
                              color: Colors.green,
                            ),
                            SizedBox(height: 16),
                            Container(
                              child: Text(
                                "Pharmacien",
                                style: GoogleFonts.aBeeZee(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Add_information_client(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(blurRadius: 5, color: Colors.indigo),
                          ],
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width / 3,
                              ),
                            ),
                            Icon(Icons.people, size: 40, color: Colors.indigo),
                            SizedBox(height: 16),
                            Container(
                              child: Text(
                                "Client",
                                style: GoogleFonts.aBeeZee(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Section
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            backgroundColor: Colors.indigo[100],
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Promos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Rwodes'),
          BottomNavigationBarItem(
            icon: IconButton(
              icon: Icon(Icons.login_outlined),
              onPressed: () {
                auth.signOut();
              },
            ),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}