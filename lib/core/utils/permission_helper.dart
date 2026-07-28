import 'package:geolocator/geolocator.dart';
import '../errors/location_exception.dart';

class PermissionHelper {
  static Future<void> checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Geolocator.openLocationSettings(); // Can't wait for this
      throw LocationException(
        message: "Location service is turned off. Please enable GPS.",
        type: LocationErrorType.serviceDisabled,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          message: "Location permissions are denied",
          type: LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        message: "Location permissions are permanently denied. Please enable them in app settings.",
        type: LocationErrorType.permissionDeniedForever,
      );
    }
  }
}
