import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacie/register.dart';
import 'package:pharmacie/situation.dart';

class Signin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Signin2(),
    );
  }
}

class Signin2 extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Signin2> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        var chek = await auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Situation()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email or password incorrect!'),
            backgroundColor: Colors.red[300],
          ),
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.sizeOf(context).height / 2,
              width: double.infinity,
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(blurRadius: 2, color: Colors.indigo)],
                color: Colors.indigo[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Text(
                    "Pharmacie Abeer",
                    style: GoogleFonts.aBeeZee(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Expanded(child: Image.asset("images/ph2.png")),
                ],
              ),
            ),
            // طبقة شفافة لتظليل الخلفية
            Container(color: Colors.black.withOpacity(0.5)),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // حقل البريد الإلكتروني
                            TextFormField(
                              controller: _emailController,
                              style: GoogleFonts.aBeeZee(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: GoogleFonts.aBeeZee(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                } else if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}',
                                ).hasMatch(value)) {
                                  return 'wrong email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            // حقل كلمة المرور
                            TextFormField(
                              controller: _passwordController,
                              style: GoogleFonts.aBeeZee(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.aBeeZee(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Password';
                                } else if (value.length < 6) {
                                  return 'Password must to be more then 6 charecter';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 30),
                            // زر تسجيل الدخول
                            ElevatedButton(
                              onPressed: _login,
                              child: Text(
                                'Sign in',
                                style: GoogleFonts.aBeeZee(
                                  fontSize: 18,
                                  color: Colors.indigo[50],
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[400],
                                padding: EdgeInsets.symmetric(
                                  horizontal: 60,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Register(),
                                  ),
                                );
                              },
                              child: Text(
                                'Create a new compte?',
                                style: GoogleFonts.aBeeZee(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
