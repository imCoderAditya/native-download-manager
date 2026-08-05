import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 10: Rich Notifications & Custom UI Showcase
class NotificationCustomUiTemplatePage extends StatelessWidget {
  final String title;
  final String? sampleUrl;
  final String? sampleFileName;

  const NotificationCustomUiTemplatePage({
    super.key,
    this.title = '10. Notifications & Custom UI',
    this.sampleUrl,
    this.sampleFileName,
  });

  void _triggerDownloadWithInteractiveNotification(BuildContext context) async {
    await NativeDownloadManager.download(
      url: sampleUrl ?? 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      fileName: sampleFileName ?? 'Notification_Demo_Video.mp4',
      priority: DownloadPriority.high,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download started! Pull down Android Notification Drawer to test Pause, Resume, Cancel & Retry buttons.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 48, color: Colors.teal),
                    const SizedBox(height: 12),
                    const Text('Interactive System Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text(
                      'Tests Android Notification Drawer Action buttons (Pause, Resume, Cancel, Retry) built into native engine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _triggerDownloadWithInteractiveNotification(context),
                      icon: const Icon(Icons.notification_add_rounded),
                      label: const Text('Trigger Notification Action Test'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
