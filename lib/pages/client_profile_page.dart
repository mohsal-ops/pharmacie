import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {

  final TextEditingController medicineName = TextEditingController();

  TimeOfDay? selectedTime;

  Future pickTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future saveReminder() async {

    if (medicineName.text.isEmpty || selectedTime == null) return;

    await NotificationService.showNotification(
      id: 1,
      title: "Medicine Reminder",
      body: "Time to take ${medicineName.text}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder saved")),
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// USER CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [

                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),

                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      user?.email ?? "User",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "Client Account",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 25),

          /// MEDICINE REMINDER SECTION
          const Text(
            "Medicine Reminder",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: medicineName,
            decoration: InputDecoration(
              hintText: "Medicine name",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [

                Expanded(
                  child: Text(
                    selectedTime == null
                        ? "Select reminder time"
                        : selectedTime!.format(context),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: pickTime,
                )
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Save Reminder"),
            ),
          ),

          const SizedBox(height: 30),

          /// EXTRA FEATURES

          ListTile(
            leading: const Icon(Icons.local_pharmacy),
            title: const Text("Saved Pharmacies"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Medicine History"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}