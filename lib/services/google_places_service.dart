import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static Future<List<Map<String, dynamic>>> getNearbyPharmacies(
      double lat, double lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=5000'
        '&type=pharmacy'
        '&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception(data['error_message'] ?? 'Places API error');
    }

    return (data['results'] as List).map((place) {
      return {
        'placeId': place['place_id'],
        'name': place['name'],
        'lat': place['geometry']['location']['lat'],
        'lng': place['geometry']['location']['lng'],
        'open': place['opening_hours']?['open_now'] ?? false,
        'address': place['vicinity'] ?? '',
      };
    }).toList();
  }
}

