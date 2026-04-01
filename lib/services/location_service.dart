import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if GPS is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Return null instead of throwing — let the UI handle it
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;  // user said no — return null
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;  // permanently denied — return null
    }

    return await Geolocator.getCurrentPosition();
  }
}