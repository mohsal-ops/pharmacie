import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class Reminder {
  int id;
  String medicine;
  String time;
  Reminder({required this.id, required this.medicine, required this.time});
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final TextEditingController medicineName = TextEditingController();
  TimeOfDay? selectedTime;
  List<Reminder> reminders = [];

  Future pickTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F9D58),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => selectedTime = time);
  }

  Future saveReminder() async {
    if (medicineName.text.trim().isEmpty || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Veuillez saisir le médicament et l'heure"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year, now.month, now.day,
      selectedTime!.hour, selectedTime!.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await NotificationService.scheduleNotification(
      id,
      "Rappel Médicament",
      "Il est l'heure de prendre ${medicineName.text}",
      scheduledTime,
    );

    setState(() {
      reminders.add(Reminder(
        id: id,
        medicine: medicineName.text,
        time: selectedTime!.format(context),
      ));
    });

    medicineName.clear();
    setState(() => selectedTime = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Rappel enregistré ✅"),
        backgroundColor: const Color(0xFF0F9D58),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future deleteReminder(int id) async {
    await NotificationService.cancelNotification(id);
    setState(() => reminders.removeWhere((r) => r.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── USER CARD ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F9D58), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F9D58).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── FIX: text overflow using Expanded + overflow
                        Text(
                          user?.email ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Compte Client',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── STATS ROW ──────────────────────────────────────────────
            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.notifications_active,
                label: 'Rappels actifs',
                value: '${reminders.length}',
                color: const Color(0xFF0F9D58),
                bg: const Color(0xFFE8F5E9),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.medication,
                label: 'Médicaments',
                value: '${reminders.map((r) => r.medicine).toSet().length}',
                color: const Color(0xFF1565C0),
                bg: const Color(0xFFE3F2FD),
              )),
            ]),

            const SizedBox(height: 28),

            // ── REMINDER SECTION TITLE ─────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alarm_add,
                    color: Color(0xFF0F9D58), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Ajouter un Rappel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // ── ADD REMINDER CARD ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(children: [

                // Medicine name input
                TextField(
                  controller: medicineName,
                  decoration: InputDecoration(
                    labelText: 'Nom du médicament',
                    prefixIcon: const Icon(Icons.medication,
                        color: Color(0xFF0F9D58)),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF0F9D58), width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Time picker row
                GestureDetector(
                  onTap: pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedTime != null
                            ? const Color(0xFF0F9D58)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          color: Color(0xFF0F9D58), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        selectedTime == null
                            ? "Sélectionner l'heure"
                            : selectedTime!.format(context),
                        style: TextStyle(
                          fontSize: 15,
                          color: selectedTime == null
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                          fontWeight: selectedTime != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ]),
                  ),
                ),

                const SizedBox(height: 14),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text(
                      'Enregistrer le rappel',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: saveReminder,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // ── SAVED REMINDERS TITLE ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications,
                        color: Color(0xFF1565C0), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Rappels Enregistrés',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ]),
                if (reminders.isNotEmpty)
                  Text(
                    '${reminders.length} actif(s)',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── REMINDER LIST ──────────────────────────────────────────
            if (reminders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun rappel configuré',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ajoutez un rappel ci-dessus',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ]),
              )
            else
              ...reminders.map((r) => _ReminderCard(
                    reminder: r,
                    onDelete: () => deleteReminder(r.id),
                  )),

            const SizedBox(height: 28),

            // ── QUICK LINKS ────────────────────────────────────────────
            const Text(
              'Raccourcis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(children: [
                _QuickLink(
                  icon: Icons.local_pharmacy,
                  label: 'Pharmacies sauvegardées',
                  color: const Color(0xFF0F9D58),
                  onTap: () {},
                  showDivider: true,
                ),
                _QuickLink(
                  icon: Icons.history,
                  label: 'Historique de médicaments',
                  color: const Color(0xFF1565C0),
                  onTap: () {},
                  showDivider: true,
                ),
                _QuickLink(
                  icon: Icons.settings,
                  label: 'Paramètres',
                  color: const Color(0xFF455A64),
                  onTap: () {},
                  showDivider: false,
                ),
              ]),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bg;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDelete;
  const _ReminderCard({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication,
              color: Color(0xFF0F9D58), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FIX: overflow on medicine name
              Text(
                reminder.medicine,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.access_time,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  reminder.time,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Actif',
            style: TextStyle(
              color: Color(0xFF0F9D58),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A2E),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.grey),
      ),
      if (showDivider)
        Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: Colors.grey.shade100),
    ]);
  }
}