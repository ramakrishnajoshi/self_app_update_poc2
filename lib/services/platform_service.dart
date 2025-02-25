import 'dart:io';
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.example.self_app_update_poc2/app_update');

  static Future<bool> installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result =
            await _channel.invokeMethod('installApk', {'filePath': filePath});
        return result ?? false;
      }
      return false;
    } on PlatformException catch (e) {
      print('Error installing APK: ${e.message}');
      return false;
    }
  }
}
