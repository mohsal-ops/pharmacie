import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicineAnalysisResult {
  final String name;
  final String dosage;
  final String expiry;
  final String manufacturer;
  final List<String> allLines;
  final List<String> labels;
  final String rawText;

  MedicineAnalysisResult({
    required this.name,
    required this.dosage,
    required this.expiry,
    required this.manufacturer,
    required this.allLines,
    required this.labels,
    required this.rawText,
  });
}

class MedicineScannerPage extends StatefulWidget {
  const MedicineScannerPage({super.key});
  @override
  State<MedicineScannerPage> createState() => _MedicineScannerPageState();
}

class _MedicineScannerPageState extends State<MedicineScannerPage> {
  final List<File> _images = [];
  MedicineAnalysisResult? _result;
  bool _loading = false;
  bool _saving  = false;
  bool _saved   = false;
  String? _error;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _priceController = TextEditingController();

  static String get _apiKey => dotenv.env['VISION_API_KEY'] ?? '';
  static const String _visionUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  // ── Crop image after picking ───────────────────────────────────────────────
  Future<File?> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer la boîte',
          toolbarColor: const Color(0xFF0F9D58),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF0F9D58),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );
    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  // ── Pick from camera then crop ─────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;

    // ── Open cropper immediately after capture ─────────────────────────────
    final cropped = await _cropImage(file.path);
    if (cropped == null) return; // user cancelled crop

    setState(() {
      _images.add(cropped);
      _result = null;
      _error  = null;
      _saved  = false;
    });
  }

  // ── Pick from gallery then crop ────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final List<XFile> files = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: 6,
    );
    if (files.isEmpty) return;

    // Crop each selected image one by one
    for (var f in files) {
      if (_images.length >= 6) break;
      final cropped = await _cropImage(f.path);
      if (cropped != null) {
        setState(() {
          _images.add(cropped);
          _result = null;
          _error  = null;
          _saved  = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _result = null;
      _saved  = false;
    });
  }

  // ── Analyze all images ─────────────────────────────────────────────────────
  Future<void> _analyze() async {
    if (_images.isEmpty) return;
    setState(() { _loading = true; _error = null; _saved = false; });

    try {
      final List<Map<String, dynamic>> requests = [];

      for (final image in _images) {
        final bytes     = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        requests.add({
          'image': {'content': base64Str},
          'features': [
            {'type': 'TEXT_DETECTION'},
            {'type': 'LABEL_DETECTION', 'maxResults': 10},
          ],
        });
      }

      final response = await http.post(
        Uri.parse('$_visionUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requests': requests}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception(
            'Vision API error ${response.statusCode}: ${response.body}');
      }

      final jsonResp  = jsonDecode(response.body);
      final responses = jsonResp['responses'] as List;

      final StringBuffer allTextBuffer = StringBuffer();
      final Set<String>  allLabels     = {};

      for (final r in responses) {
        final textAnnotations  = r['textAnnotations']  as List? ?? [];
        final labelAnnotations = r['labelAnnotations'] as List? ?? [];
        if (textAnnotations.isNotEmpty) {
          allTextBuffer.writeln(textAnnotations[0]['description'] ?? '');
        }
        for (final l in labelAnnotations) {
          allLabels.add(l['description'] as String);
        }
      }

      final String fullText = allTextBuffer.toString();
      final lines = fullText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.length > 1)
          .toList();

      final medicineName = lines.isNotEmpty ? lines[0] : 'Inconnu';

      final dosageRegex = RegExp(
          r'(\d+\.?\d*\s?(mg|g|ml|mcg|IU))', caseSensitive: false);
      final dosageMatch = dosageRegex.firstMatch(fullText);
      final dosage      = dosageMatch?.group(0) ?? 'Non détecté';

      final expiryRegex = RegExp(
          r'(exp|expiry|expires?|use before|best before|peremption|perem)[:\s]*([\d\/\-\.]+)',
          caseSensitive: false);
      final expiryMatch = expiryRegex.firstMatch(fullText);
      final expiry      = expiryMatch?.group(2) ?? 'Non détecté';

      final mfgKeywords = [
        'laboratoire', 'lab', 'pharma', 'manufactured',
        'mfg', 'sanofi', 'bayer', 'pfizer', 'novartis',
        'roche', 'saidal', 'produced by', 'fabriqué',
      ];
      final manufacturer = lines.firstWhere(
        (l) => mfgKeywords.any((k) => l.toLowerCase().contains(k)),
        orElse: () => 'Non détecté',
      );

      setState(() {
        _result = MedicineAnalysisResult(
          name:         medicineName,
          dosage:       dosage,
          expiry:       expiry,
          manufacturer: manufacturer,
          allLines:     lines,
          labels:       allLabels.toList(),
          rawText:      fullText,
        );
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Save to Firestore ──────────────────────────────────────────────────────
  Future<void> _saveToPharmacy() async {
    if (_result == null) return;
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un prix valide')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(uid)
          .update({
        'medicines': FieldValue.arrayUnion([
          {'name': _result!.name, 'price': price, 'available': true}
        ]),
      });
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_result!.name} ajouté ✅'),
        backgroundColor: Colors.teal,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  void _reset() {
    setState(() {
      _images.clear();
      _result = null;
      _error  = null;
      _saved  = false;
      _priceController.clear();
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Scanner Médicament',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_images.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Info banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.crop, color: Color(0xFF1565C0), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Après chaque photo, recadrez pour ne garder '
                    'que la face de la boîte. Cela améliore '
                    'la précision de la détection.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF1565C0)),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Image grid ─────────────────────────────────────────────
            if (_images.isEmpty)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.grey.shade300, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Aucune photo ajoutée',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('La photo sera recadrée après capture',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12)),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _images[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Cropped badge
                    Positioned(
                      top: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crop, color: Colors.white,
                                size: 10),
                            SizedBox(width: 2),
                            Text('OK',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // Remove button
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    // Face number
                    Positioned(
                      bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Face ${index + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ]);
                },
              ),

            const SizedBox(height: 14),

            // ── Buttons ────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Caméra'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed:
                      _images.length >= 6 ? null : _pickFromCamera,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed:
                      _images.length >= 6 ? null : _pickFromGallery,
                ),
              ),
            ]),

            if (_images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_images.length}/6 photo(s) — '
                  '${_images.length >= 6 ? "maximum atteint" : "vous pouvez en ajouter d\'autres"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _images.length >= 6
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // ── Analyze button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.biotech),
                label: Text(
                  _images.length > 1
                      ? 'Analyser ${_images.length} photos'
                      : 'Analyser le médicament',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed:
                    (_images.isEmpty || _loading) ? null : _analyze,
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              Column(children: [
                const CircularProgressIndicator(
                    color: Color(0xFF0F9D58)),
                const SizedBox(height: 10),
                Text(
                  _images.length > 1
                      ? 'Analyse de ${_images.length} photos...'
                      : 'Analyse en cours...',
                  style: const TextStyle(color: Colors.grey),
                ),
              ]),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),

            if (_result != null) ...[
              _buildResultCard(_result!),
              const SizedBox(height: 16),
              _buildSaveSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(MedicineAnalysisResult r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          blurRadius: 12,
          color: Colors.black.withOpacity(0.06),
          offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF0F9D58), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Résultat de l\'analyse',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_images.length} photo(s)',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0F9D58),
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const Divider(height: 24),
          _infoRow(Icons.medication,     'Nom',        r.name),
          _infoRow(Icons.science,        'Dosage',     r.dosage),
          _infoRow(Icons.calendar_today, 'Péremption', r.expiry),
          _infoRow(Icons.business,       'Fabricant',  r.manufacturer),
          const SizedBox(height: 12),
          if (r.labels.isNotEmpty) ...[
            const Text('Étiquettes détectées :',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: r.labels
                  .map((l) => Chip(
                        label: Text(l,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor:
                            Colors.teal.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text('Tout le texte détecté',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            children: r.allLines
                .map((line) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.text_fields, size: 14),
                      title: Text(line,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveSection() {
    if (_saved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle, color: Colors.teal),
          SizedBox(width: 10),
          Text('Médicament ajouté à votre pharmacie !',
              style: TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          blurRadius: 12,
          color: Colors.black.withOpacity(0.06),
          offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajouter à votre pharmacie',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _priceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Prix (DA)',
              prefixIcon: const Icon(Icons.attach_money,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving
                  ? 'Enregistrement...'
                  : 'Ajouter à la pharmacie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text('$label :',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF455A64))),
          ),
        ],
      ),
    );
  }
}