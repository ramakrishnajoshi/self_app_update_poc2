import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:version/version.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:self_app_update_poc2/services/platform_service.dart';

class UpdateService {
  // Mock API URL - replace with your actual API endpoint
  final String apiUrl =
      'https://run.mocky.io/v3/0d30a47d-9316-4d26-8927-9a38991194f3';

  // Singleton pattern
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // Add a cancellation token
  CancelToken? _cancelToken;

  // Method to cancel ongoing download
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      print('Cancelling download...');
      _cancelToken!.cancel('Download cancelled by user');
      _cancelToken = null;
    }
  }

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      // Check for internet connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return {'hasUpdate': false, 'error': 'No internet connection'};
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      // Call API to get latest version info
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = Version.parse(data['newVersion']);
        final downloadUrl = data['downloadUrl'];
        final isCritical = data['isCritical'];

        // Compare versions
        if (latestVersion > currentVersion) {
          return {
            'hasUpdate': true,
            'currentVersion': currentVersion.toString(),
            'newVersion': latestVersion.toString(),
            'downloadUrl': downloadUrl,
            'isCritical': isCritical,
          };
        } else {
          return {'hasUpdate': false};
        }
      } else {
        return {'hasUpdate': false, 'error': 'Failed to fetch update info'};
      }
    } catch (e) {
      return {'hasUpdate': false, 'error': e.toString()};
    }
  }

  Future<void> downloadAndInstallUpdate(
    String url,
    Function(double) onProgress,
    Function() onSuccess,
    Function(String) onError,
  ) async {
    try {
      print('Starting download from URL: $url');

      // Create a new cancel token for this download
      _cancelToken = CancelToken();

      // For Android 10+ we don't need to request storage permission for app-specific directories
      Directory? directory;

      if (Platform.isAndroid) {
        // Use app-specific directory which doesn't require storage permission
        directory = await getExternalStorageDirectory();
        print('Using external storage directory: ${directory?.path}');
      } else {
        // Fallback for other platforms
        directory = await getTemporaryDirectory();
        print('Using temporary directory: ${directory?.path}');
      }

      if (directory == null) {
        print('Error: Could not access storage directory');
        onError('Could not access storage');
        return;
      }

      final filePath = '${directory.path}/app_update.apk';
      print('APK will be saved to: $filePath');

      // Download file with progress
      final dio = Dio();

      print('Starting Dio download...');
      await dio.download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            print(
                'Download progress: received=$received, total=$total, progress=${(progress * 100).toStringAsFixed(1)}%');
            onProgress(progress);
          } else {
            print('Download progress: received=$received, total=unknown');
          }
        },
      );
      print('Dio download completed');

      // Clear the cancel token after successful download
      _cancelToken = null;

      // Install APK
      final file = File(filePath);
      if (await file.exists()) {
        print('APK file exists at path: $filePath');
        // Request install packages permission
        print('Requesting install packages permission');
        var installStatus = await Permission.requestInstallPackages.request();
        if (installStatus.isGranted) {
          print('Install packages permission granted');
          // Use the platform service to install the APK
          print('Launching APK installation');
          final installed = await PlatformService.installApk(filePath);
          if (installed) {
            print('Installation launched successfully');
            onSuccess();
          } else {
            print('Failed to launch installation');
            onError('Failed to launch installation');
          }
        } else {
          print('Install packages permission denied');
          onError('Permission to install packages is required');
        }
      } else {
        print('Error: APK file does not exist after download');
        onError('Download failed - file not found');
      }
    } catch (e) {
      // Check if the error is due to cancellation
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print('Download was cancelled by user');
        onError('Download cancelled');
      } else {
        print('Error during update: $e');
        onError('Error during update: ${e.toString()}');
      }

      // Clear the cancel token on error
      _cancelToken = null;
    }
  }
}
