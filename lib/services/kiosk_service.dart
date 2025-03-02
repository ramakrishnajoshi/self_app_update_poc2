import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel =
      MethodChannel('com.example.self_app_update_poc2/kiosk');

  static Future<bool> startKioskMode() async {
    try {
      final bool result = await _channel.invokeMethod('startKioskMode');
      return result;
    } on PlatformException catch (e) {
      print('Error starting kiosk mode: ${e.message}');
      return false;
    }
  }

  static Future<bool> stopKioskMode() async {
    try {
      final bool result = await _channel.invokeMethod('stopKioskMode');
      return result;
    } on PlatformException catch (e) {
      print('Error stopping kiosk mode: ${e.message}');
      return false;
    }
  }

  static Future<bool> isInKioskMode() async {
    try {
      final bool result = await _channel.invokeMethod('isInKioskMode');
      return result;
    } on PlatformException catch (e) {
      print('Error checking kiosk mode: ${e.message}');
      return false;
    }
  }
}
