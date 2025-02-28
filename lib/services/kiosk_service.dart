import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel =
      MethodChannel('com.example.self_app_update_poc2/kiosk');

  // Check if the app is the device owner
  static Future<bool> isDeviceOwner() async {
    try {
      final bool isOwner = await _channel.invokeMethod('isDeviceOwner');
      return isOwner;
    } on PlatformException catch (e) {
      print('Error checking device owner status: ${e.message}');
      return false;
    }
  }

  // Start lock task mode (kiosk mode)
  static Future<bool> startLockTask() async {
    try {
      final bool success = await _channel.invokeMethod('startLockTask');
      return success;
    } on PlatformException catch (e) {
      print('Error starting lock task: ${e.message}');
      return false;
    }
  }

  // Stop lock task mode
  static Future<bool> stopLockTask() async {
    try {
      final bool success = await _channel.invokeMethod('stopLockTask');
      return success;
    } on PlatformException catch (e) {
      print('Error stopping lock task: ${e.message}');
      return false;
    }
  }
}
