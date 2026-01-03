import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class Add_information_pharmacy extends StatelessWidget {
  const Add_information_pharmacy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      //  theme: ThemeData(primarySwatch: Colors.indigo),
      home: Add_information_pharmacy2(),
    );
  }
}

class Add_information_pharmacy2 extends StatefulWidget {
  const Add_information_pharmacy2({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Add_information_pharmacy2> {
  final cloud_profile_pharmacy = FirebaseFirestore.instance.collection(
    "profile_pharmacy",
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yassir Cash Section
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: MediaQuery.sizeOf(context).height / 3,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(blurRadius: 1, color: Colors.indigo),
                        ],
                        color: Colors.indigo[200],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          Text(
                            "Pharmacien app",
                            style: GoogleFonts.aBeeZee(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Expanded(child: Image.asset("images/Ph2.png")),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.sizeOf(context).height / 26),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            child: Text(
                              "You as pharmacy!",
                              style: GoogleFonts.aBeeZee(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              "The pharmacist is always at the service of the citizen, don't forget that..",
                              style: GoogleFonts.aBeeZee(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // SizedBox(height: MediaQuery.sizeOf(context).height / 5),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.people_outline_sharp),
                          ),

                          // label: Text("Phone number"),
                          hintText: "Name",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: _adressController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.house),
                          ),

                          // label: Text("Phone number"),
                          hintText: "Adress",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.phone_android),
                          ),

                          // label: Text("Phone number"),
                          hintText: "+213 123456789",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        String name = _nameController.text.toString();
                        String adress = _adressController.text.toString();
                        String phone = _phoneController.text.toString();

                        if (phone.isEmpty || name.isEmpty || adress.isEmpty) {
                          _showSnackBar(context, 'Cant be empty');
                        } else {
                          cloud_profile_pharmacy.add({
                            "user_id": auth.currentUser!.uid,
                            "name": _nameController.text,
                            "phone": _phoneController.text,
                            "adress": _adressController.text,
                            "situation": "pharmacy",
                          });
                          _phoneController.clear();
                          _nameController.clear();
                          _adressController.clear();
                        }
                      },
                      child: Text("Send"),
                      
                    ),
                    ElevatedButton(
                      onPressed: () {
                       
                        
                          cloud_profile_pharmacy.add({
                           
                            "situation": "pharmacy",
                          });
                          _phoneController.clear();
                          _nameController.clear();
                          _adressController.clear();
                        },
                    
                      child: Text("Send"),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[300]),
    );
  }
}
