import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'medicine_scanner_page.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});
  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    _MedicineInventoryPage(),
    _ScannerTab(),
    _PharmacyProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0F9D58),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Dashboard Home
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final medicines = data?['medicines'] as List<dynamic>? ?? [];
        final isOpen    = data?['open'] as bool? ?? false;
        final name      = data?['name'] as String? ?? 'Your Pharmacy';

        final totalCount     = medicines.length;
        final availableCount = medicines.where((m) => m['available'] == true).length;
        final outOfStock     = totalCount - availableCount;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()} 👋',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                    _StatusToggle(uid: uid, isOpen: isOpen),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Stats row ─────────────────────────────────────────────
                Row(children: [
                  Expanded(child: _StatCard(
                    icon: Icons.medication,
                    label: 'Total',
                    value: '$totalCount',
                    color: const Color(0xFF0F9D58),
                    bg: const Color(0xFFE8F5E9),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.check_circle,
                    label: 'Disponible',
                    value: '$availableCount',
                    color: const Color(0xFF1565C0),
                    bg: const Color(0xFFE3F2FD),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.remove_circle,
                    label: 'En rupture de stock',
                    value: '$outOfStock',
                    color: const Color(0xFFE53935),
                    bg: const Color(0xFFFFEBEE),
                  )),
                ]),

                const SizedBox(height: 24),

                // ── Quick actions ─────────────────────────────────────────
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _QuickAction(
                    icon: Icons.add_box,
                    label: 'Ajouter des médicaments',
                    color: const Color(0xFF0F9D58),
                    onTap: () => _showAddMedicineSheet(context, uid),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Boîte',
                    color: const Color(0xFF7B1FA2),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MedicineScannerPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    color: const Color(0xFFE53935),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (r) => false,
                      );
                    },
                  )),
                ]),

                const SizedBox(height: 24),

                // ── Recent medicines ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Médicaments récents',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                    Text('${medicines.length} total',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),

                if (medicines.isEmpty)
                  _EmptyInventory(
                      onAdd: () => _showAddMedicineSheet(context, uid))
                else
                  ...medicines.reversed.take(5).map((m) =>
                      _RecentMedicineRow(medicine: m)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  static void _showAddMedicineSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMedicineSheet(uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Full Inventory
// ─────────────────────────────────────────────────────────────────────────────
class _MedicineInventoryPage extends StatefulWidget {
  const _MedicineInventoryPage();
  @override
  State<_MedicineInventoryPage> createState() => _MedicineInventoryPageState();
}

class _MedicineInventoryPageState extends State<_MedicineInventoryPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inventaire',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un médicament...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pharmacies')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>?;
                final all =
                    (data?['medicines'] as List<dynamic>? ?? []);
                final filtered = _query.isEmpty
                    ? all
                    : all.where((m) => (m['name'] as String)
                        .toLowerCase()
                        .contains(_query))
                        .toList();

                if (all.isEmpty) {
                  return _EmptyInventory(
                      onAdd: () => _showAdd(context, uid));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final m = filtered[i] as Map<String, dynamic>;
                    return _InventoryCard(
                      medicine: m,
                      uid: uid,
                      allMedicines: all,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAdd(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMedicineSheet(uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Scanner Tab
// ─────────────────────────────────────────────────────────────────────────────
class _ScannerTab extends StatelessWidget {
  const _ScannerTab();
  @override
  Widget build(BuildContext context) {
    return const MedicineScannerPage();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — Pharmacy Profile
// ─────────────────────────────────────────────────────────────────────────────
class _PharmacyProfilePage extends StatelessWidget {
  const _PharmacyProfilePage();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name    = data?['name']    as String? ?? 'Votre pharmacie';
          final address = data?['address'] as String? ?? 'No address';
          final email   = data?['ownerEmail'] as String? ?? '';
          final isOpen  = data?['open'] as bool? ?? false;
          final meds    = (data?['medicines'] as List<dynamic>? ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar ───────────────────────────────────────────────
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9D58),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.local_pharmacy,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                _StatusBadge(isOpen: isOpen),
                const SizedBox(height: 24),

                // ── Info card ────────────────────────────────────────────
                _ProfileCard(children: [
                  _ProfileRow(Icons.location_on, 'Address', address),
                  const Divider(height: 20),
                  _ProfileRow(Icons.medication,
                      'Médicaments totaux', '${meds.length}'),
                  const Divider(height: 20),
                  _ProfileRow(Icons.check_circle, 'Disponible',
                      '${meds.where((m) => m['available'] == true).length}'),
                ]),

                const SizedBox(height: 16),

                // ── Open/Close toggle ─────────────────────────────────
                _ProfileCard(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [
                        Icon(Icons.storefront,
                            color: Color(0xFF0F9D58)),
                        SizedBox(width: 10),
                        Text('Statut de la pharmacie',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ]),
                      Switch(
                        value: isOpen,
                        activeThumbColor: const Color(0xFF0F9D58),
                        onChanged: (v) => FirebaseFirestore.instance
                            .collection('pharmacies')
                            .doc(uid)
                            .update({'open': v}),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Sign out ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                        (r) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatusToggle extends StatelessWidget {
  final String uid;
  final bool isOpen;
  const _StatusToggle({required this.uid, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(uid)
          .update({'ouvert': !isOpen}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isOpen
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isOpen
                  ? const Color(0xFF0F9D58)
                  : const Color(0xFFE53935)),
        ),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isOpen
                  ? const Color(0xFF0F9D58)
                  : const Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'OUVERT' : 'FERMÉ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isOpen
                  ? const Color(0xFF0F9D58)
                  : const Color(0xFFE53935),
            ),
          ),
        ]),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}

class _RecentMedicineRow extends StatelessWidget {
  final dynamic medicine;
  const _RecentMedicineRow({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final bool available = medicine['available'] as bool? ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.medication,
              color: Color(0xFF0F9D58), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            medicine['name'] ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Text(
          '${medicine['price']} DA',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F9D58)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: available
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            available ? '✓' : '✗',
            style: TextStyle(
                fontSize: 12,
                color: available
                    ? const Color(0xFF0F9D58)
                    : const Color(0xFFE53935)),
          ),
        ),
      ]),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final String uid;
  final List<dynamic> allMedicines;
  const _InventoryCard({
    required this.medicine,
    required this.uid,
    required this.allMedicines,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = medicine['available'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: available
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.medication,
              color: available
                  ? const Color(0xFF0F9D58)
                  : const Color(0xFFE53935),
              size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(medicine['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${medicine['price']} DA',
                  style: const TextStyle(
                      color: Color(0xFF0F9D58),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Toggle availability
        Switch(
          value: available,
          activeColor: const Color(0xFF0F9D58),
          onChanged: (v) => _toggleAvailability(v),
        ),
        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.red, size: 20),
          onPressed: () => _confirmDelete(context),
        ),
      ]),
    );
  }

  Future<void> _toggleAvailability(bool newVal) async {
    final updated = allMedicines.map((m) {
      if (m['name'] == medicine['name'] &&
          m['price'] == medicine['price']) {
        return {...m as Map<String, dynamic>, 'available': newVal};
      }
      return m;
    }).toList();

    await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(uid)
        .update({'médicaments': updated});
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Supprimer le médicament'),
        content:
            Text('Retirer "${medicine['name']}" de votre inventaire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('pharmacies')
                  .doc(uid)
                  .update({
                'medicines':
                    FieldValue.arrayRemove([medicine])
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddMedicineSheet extends StatefulWidget {
  final String uid;
  const _AddMedicineSheet({required this.uid});
  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _available  = true;
  bool _saving     = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Ajouter un médicament',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _SheetField(
              controller: _nameCtrl,
              label: 'Nom du médicament',
              icon: Icons.medication),
          const SizedBox(height: 14),
          _SheetField(
              controller: _priceCtrl,
              label: 'Prix (DA)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Disponible en stock',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15)),
              Switch(
                value: _available,
                activeThumbColor: const Color(0xFF0F9D58),
                onChanged: (v) => setState(() => _available = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Ajouter le médicament',
                      style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs correctement')),
      );
      return;
    }

    setState(() => _saving = true);

    await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(widget.uid)
        .update({
      'medicines': FieldValue.arrayUnion([
        {'name': name, 'price': price, 'available': _available}
      ])
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$name ajouté avec succès✅'),
            backgroundColor: const Color(0xFF0F9D58)),
      );
    }
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0F9D58)),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF0F9D58), width: 2),
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyInventory({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.inventory_2_outlined,
            size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('Aucun médicament pour le moment',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter votre premier médicament'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58)),
          onPressed: onAdd,
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? '● OUVERT' : '● FERMÉ',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOpen
                ? const Color(0xFF0F9D58)
                : const Color(0xFFE53935)),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0F9D58), size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}