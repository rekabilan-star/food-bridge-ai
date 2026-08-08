import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<bool> canCheckBiometrics() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access FoodBridge AI',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return {
        'deviceInfo': '${androidInfo.manufacturer} ${androidInfo.model}',
        'os': 'Android ${androidInfo.version.release}',
      };
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return {
        'deviceInfo': iosInfo.name,
        'os': 'iOS ${iosInfo.systemVersion}',
      };
    }
    return {'deviceInfo': 'Unknown', 'os': 'Unknown'};
  }

  static Future<void> saveBiometricPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  static Future<bool> getBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }
}
