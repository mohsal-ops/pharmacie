import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Register2());
  }
}

class Register2 extends StatefulWidget {
  const Register2({super.key});

  @override
  State<Register2> createState() => _Register2State();
}

class _Register2State extends State<Register2> {
  final auth = FirebaseAuth.instance;
  final cloud_profile_pharmacy = FirebaseFirestore.instance.collection(
    "profile_pharmacy",
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("pharmacie")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              await auth.createUserWithEmailAndPassword(
                email: "zchabir3@gmail.com",
                password: "Fares23",
              );
            },
            child: Text(" send "),
          ),
          ElevatedButton(
            onPressed: () async {
              await cloud_profile_pharmacy.add({
                "name": "fares",
                "Adress": "setif",
              });
            },
            child: Text(" send "),
          ),
        ],
      ),
    );
  }
}
