import 'package:flutter/material.dart';

class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final bool isCritical;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    Key? key,
    required this.currentVersion,
    required this.newVersion,
    required this.isCritical,
    required this.onUpdate,
    this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
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
          // Update icon
          const Icon(
            Icons.system_update,
            color: Colors.blue,
            size: 64,
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            isCritical ? 'Critical Update Required' : 'Update Available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Version info
          Text(
            'Current version: $currentVersion\nNew version: $newVersion',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Update message
          Text(
            isCritical
                ? 'This update contains critical changes and is required to continue using the app.'
                : 'A new version of the app is available with new features and improvements.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isCritical) ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onLater != null) onLater!();
                  },
                  child: const Text('Later'),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUpdate();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(isCritical ? 'Update Now' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
