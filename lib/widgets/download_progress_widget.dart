import 'package:flutter/material.dart';
import 'package:self_app_update_poc2/services/update_service.dart';

class DownloadProgressWidget extends StatefulWidget {
  final String url;
  final Function(String) onError;
  final Function() onSuccess;
  final Function() onCancel;

  const DownloadProgressWidget({
    Key? key,
    required this.url,
    required this.onError,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<DownloadProgressWidget> createState() => _DownloadProgressWidgetState();
}

class _DownloadProgressWidgetState extends State<DownloadProgressWidget> {
  double _progress = 0.0;
  final UpdateService _updateService = UpdateService();
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    await _updateService.downloadAndInstallUpdate(
      widget.url,
      (progress) {
        // Log the progress
        print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');

        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      },
      () {
        // Log success
        print('Download completed successfully');
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess();
        }
      },
      (error) {
        // Log error
        print('Download failed: $error');
        if (mounted && !_isCancelling) {
          Navigator.of(context).pop();
          widget.onError(error);
        } else if (_isCancelling) {
          // If we're cancelling, just call the onCancel callback
          widget.onCancel();
        }
      },
    );
  }

  void _cancelDownload() {
    setState(() {
      _isCancelling = true;
    });

    // Cancel the download
    _updateService.cancelDownload();

    // Close the dialog
    Navigator.of(context).pop();

    // Notify the parent
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).toStringAsFixed(1);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Downloading Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 10),

            // Percentage text
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Cancel button
            TextButton(
              onPressed: _isCancelling ? null : _cancelDownload,
              child: _isCancelling
                  ? const Text('Cancelling...')
                  : const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Make sure to cancel the download if the widget is disposed
    _updateService.cancelDownload();
    super.dispose();
  }
}
