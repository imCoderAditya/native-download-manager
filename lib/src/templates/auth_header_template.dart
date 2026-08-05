import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 05: Authenticated & Header Download Manager
class AuthHeaderTemplatePage extends StatefulWidget {
  final String title;
  final String? protectedUrl;
  final String? fileName;
  final String? initialToken;
  final String? initialCustomHeader;

  const AuthHeaderTemplatePage({
    super.key,
    this.title = '05. Auth Header Downloader',
    this.protectedUrl,
    this.fileName,
    this.initialToken,
    this.initialCustomHeader,
  });

  @override
  State<AuthHeaderTemplatePage> createState() => _AuthHeaderTemplatePageState();
}

class _AuthHeaderTemplatePageState extends State<AuthHeaderTemplatePage> {
  late final TextEditingController _tokenController;
  late final TextEditingController _customHeaderController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.initialToken ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    );
    _customHeaderController = TextEditingController(
      text: widget.initialCustomHeader ?? 'X-App-Client-ID: mobile_flutter_v1.0',
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _customHeaderController.dispose();
    super.dispose();
  }

  void _downloadProtectedFile() async {
    final token = _tokenController.text.trim();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/pdf',
    };

    final custom = _customHeaderController.text.trim();
    if (custom.contains(':')) {
      final parts = custom.split(':');
      headers[parts[0].trim()] = parts[1].trim();
    }

    try {
      await NativeDownloadManager.download(
        url: widget.protectedUrl ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileName: widget.fileName ?? 'Protected_Report.pdf',
        headers: headers,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enqueued authenticated download!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security_rounded, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('API Authentication & Custom Headers', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(labelText: 'Bearer Auth Token', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customHeaderController,
                      decoration: const InputDecoration(labelText: 'Custom Key:Value Header', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _downloadProtectedFile,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Download Protected Resource'),
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
