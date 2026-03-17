import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_medicine_service.dart';

class MedicineScannerPage extends StatefulWidget {
  const MedicineScannerPage({super.key});

  @override
  State<MedicineScannerPage> createState() => _MedicineScannerPageState();
}

class _MedicineScannerPageState extends State<MedicineScannerPage> {
  File?                   _image;
  MedicineAnalysisResult? _result;
  bool                    _loading  = false;
  bool                    _saving   = false;
  bool                    _saved    = false;
  String?                 _error;
  final ImagePicker       _picker   = ImagePicker();
  final TextEditingController _priceController = TextEditingController();

  // ── Pick from camera ───────────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() {
      _image  = File(file.path);
      _result = null;
      _error  = null;
      _saved  = false;
    });
  }

  // ── Pick from gallery ──────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() {
      _image  = File(file.path);
      _result = null;
      _error  = null;
      _saved  = false;
    });
  }

  // ── Send image to Cloud Function ───────────────────────────────────────
  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() { _loading = true; _error = null; _saved = false; });
    try {
      final result = await AiMedicineService.analyzeImage(_image!);
      setState(() { _result = result; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Save medicine to Firestore ─────────────────────────────────────────
  Future<void> _saveToPharmacy() async {
    if (_result == null) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price first')),
      );
      return;
    }

    setState(() { _saving = true; });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Same structure your pharmacy_medicines.dart already uses
      final medicine = {
        'name':      _result!.name,
        'price':     price,
        'available': true,
      };

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(uid)
          .update({
        'medicines': FieldValue.arrayUnion([medicine]),
      });

      setState(() { _saved = true; });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_result!.name} added to your pharmacy ✅'),
          backgroundColor: Colors.teal,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { _saving = false; });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Medicine Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Image preview ────────────────────────────────────────────
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image == null
                ? const Center(
                    child: Icon(Icons.camera_alt, size: 64, color: Colors.grey))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
            ),
            const SizedBox(height: 16),

            // ── Camera / Gallery buttons ─────────────────────────────────
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _pickFromGallery,
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Analyze button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.biotech),
                label: const Text('Analyze Medicine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_image == null || _loading) ? null : _analyze,
              ),
            ),
            const SizedBox(height: 20),

            // ── Loading indicator ────────────────────────────────────────
            if (_loading)
              const Center(child: CircularProgressIndicator()),

            // ── Error display ────────────────────────────────────────────
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // ── Result card + save section ───────────────────────────────
            if (_result != null) ...[
              _buildResultCard(_result!),
              const SizedBox(height: 20),
              _buildSaveSection(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Result card ──────────────────────────────────────────────────────────
  Widget _buildResultCard(MedicineAnalysisResult r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Result',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _infoRow(Icons.medication,     'Name',         r.name),
          _infoRow(Icons.science,        'Dosage',       r.dosage),
          _infoRow(Icons.calendar_today, 'Expiry',       r.expiry),
          _infoRow(Icons.business,       'Manufacturer', r.manufacturer),
          const SizedBox(height: 12),
          if (r.labels.isNotEmpty) ...[
            const Text(
              'Detected labels:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: r.labels
                .map((l) => Chip(
                      label: Text(l, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.teal.withOpacity(0.1),
                    ))
                .toList(),
            ),
          ],
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text(
              'All detected text lines',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            children: r.allLines
              .map((line) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.text_fields, size: 16),
                    title: Text(line, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          ),
        ],
      ),
    );
  }

  // ── Save section (price input + save button) ─────────────────────────────
  Widget _buildSaveSection() {
    // If already saved, show a success message instead
    if (_saved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal),
            SizedBox(width: 10),
            Text(
              'Medicine saved to your pharmacy!',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add to Your Pharmacy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Price input
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price (DA)',
              prefixIcon: const Icon(Icons.attach_money),
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Add to Pharmacy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _saveToPharmacy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}