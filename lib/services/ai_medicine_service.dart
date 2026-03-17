import 'dart:convert';
import 'dart:io';
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

class AiMedicineService {

  // Your Google Cloud Vision API key
  // Get it from: console.cloud.google.com → APIs → Vision API → Credentials
  static final String _apiKey = dotenv.env['VISION_API_KEY'] ?? '';

  static final String _visionUrl =
    'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  static Future<MedicineAnalysisResult> analyzeImage(File imageFile) async {

    // 1. Read and encode image
    final bytes     = await imageFile.readAsBytes();
    final base64Str = base64Encode(bytes);

    // 2. Build Vision API request body
    final requestBody = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Str},
          'features': [
            {'type': 'TEXT_DETECTION'},
            {'type': 'LABEL_DETECTION', 'maxResults': 10},
          ],
        }
      ]
    });

    // 3. Send request directly to Google Vision
    final response = await http.post(
      Uri.parse(_visionUrl),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Vision API error ${response.statusCode}: ${response.body}');
    }

    final json      = jsonDecode(response.body);
    final responses = json['responses'][0];

    // 4. Extract text
    final textAnnotations  = responses['textAnnotations']  as List? ?? [];
    final labelAnnotations = responses['labelAnnotations'] as List? ?? [];

    final fullText = textAnnotations.isNotEmpty
      ? textAnnotations[0]['description'] as String
      : '';

    final labels = labelAnnotations
      .map((l) => l['description'] as String)
      .toList();

    final lines = fullText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.length > 1)
      .toList();

    // 5. Parse medicine info
    final medicineName = lines.isNotEmpty ? lines[0] : 'Unknown';

    final dosageRegex   = RegExp(r'(\d+\.?\d*\s?(mg|g|ml|mcg|IU))', caseSensitive: false);
    final dosageMatch   = dosageRegex.firstMatch(fullText);
    final dosage        = dosageMatch?.group(0) ?? 'Not detected';

    final expiryRegex   = RegExp(r'(exp|expiry|expires?|use before)[:\s]*([\d\/\-\.]+)', caseSensitive: false);
    final expiryMatch   = expiryRegex.firstMatch(fullText);
    final expiry        = expiryMatch?.group(2) ?? 'Not detected';

    final mfgKeywords   = ['laboratoire', 'lab', 'pharma', 'manufactured', 'mfg', 'sanofi'];
    final manufacturer  = lines.firstWhere(
      (l) => mfgKeywords.any((k) => l.toLowerCase().contains(k)),
      orElse: () => 'Not detected',
    );

    return MedicineAnalysisResult(
      name:         medicineName,
      dosage:       dosage,
      expiry:       expiry,
      manufacturer: manufacturer,
      allLines:     lines,
      labels:       labels,
      rawText:      fullText,
    );
  }
}