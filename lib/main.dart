import 'dart:io';

import 'package:flutter/material.dart';
import 'package:self_app_update_poc2/services/update_service.dart';
import 'package:self_app_update_poc2/services/kiosk_service.dart';
import 'package:self_app_update_poc2/widgets/update_dialog.dart';
import 'package:self_app_update_poc2/widgets/download_progress_widget.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'App Update Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final UpdateService _updateService = UpdateService();
  bool _isCheckingForUpdates = false;
  bool _isDownloading = false;
  bool _isDeviceOwner = false;
  bool _isInKioskMode = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Check for updates when the app starts
    _checkForUpdates();
    _requestNotificationPermission();
    _checkDeviceOwnerStatus();
  }

  Future<void> _checkDeviceOwnerStatus() async {
    if (Platform.isAndroid) {
      final isOwner = await KioskService.isDeviceOwner();
      setState(() {
        _isDeviceOwner = isOwner;
      });

      if (_isDeviceOwner) {
        _startKioskMode();
      }
    }
  }

  Future<void> _startKioskMode() async {
    if (Platform.isAndroid && _isDeviceOwner) {
      final success = await KioskService.startLockTask();
      setState(() {
        _isInKioskMode = success;
      });
    }
  }

  Future<void> _stopKioskMode() async {
    if (Platform.isAndroid && _isInKioskMode) {
      final success = await KioskService.stopLockTask();
      setState(() {
        _isInKioskMode = !success;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingForUpdates) return;

    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      final updateInfo = await _updateService.checkForUpdates();

      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        // Show update dialog
        if (mounted) {
          _showUpdateDialog(
            updateInfo['currentVersion'],
            updateInfo['newVersion'],
            updateInfo['downloadUrl'],
            updateInfo['isCritical'],
          );
        }
      } else if (updateInfo != null && updateInfo['error'] != null) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${updateInfo['error']}')),
          );
        }
      } else {
        // No update available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your app is up to date')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for updates: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  void _showUpdateDialog(
    String currentVersion,
    String newVersion,
    String downloadUrl,
    bool isCritical,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isCritical,
      builder: (context) => UpdateDialog(
        currentVersion: currentVersion,
        newVersion: newVersion,
        isCritical: isCritical,
        onUpdate: () => _startDownload(downloadUrl),
        onLater: isCritical
            ? null
            : () {
                // Do nothing for now, user chose to update later
              },
      ),
    );
  }

  void _startDownload(String url) {
    setState(() {
      _isDownloading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressWidget(
        url: url,
        onSuccess: () {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Update downloaded successfully. Installing...')),
          );
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $error')),
          );
        },
        onCancel: () {
          setState(() {
            _isDownloading = false;
          });
        },
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    // Only needed for Android 13+ (API 33+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'App Update Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCheckingForUpdates ? null : _checkForUpdates,
              child: _isCheckingForUpdates
                  ? const CircularProgressIndicator()
                  : const Text('Check for Updates'),
            ),

            // Add kiosk mode status and controls
            if (Platform.isAndroid) ...[
              const SizedBox(height: 40),
              Text(
                'Device Owner Status: ${_isDeviceOwner ? "Enabled" : "Disabled"}',
                style: TextStyle(
                  color: _isDeviceOwner ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kiosk Mode: ${_isInKioskMode ? "Active" : "Inactive"}',
                style: TextStyle(
                  color: _isInKioskMode ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_isDeviceOwner && !_isInKioskMode)
                ElevatedButton(
                  onPressed: _startKioskMode,
                  child: const Text('Start Kiosk Mode'),
                ),
              if (_isInKioskMode)
                ElevatedButton(
                  onPressed: _stopKioskMode,
                  child: const Text('Exit Kiosk Mode'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
