import 'package:location/location.dart';

class LocationService {
  static final Location _location = Location();

  static Future<LocationData> getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
    }

    // Check permission
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permission denied.');
      }
    }

    // Get current location
    return await _location.getLocation();
  }
}
