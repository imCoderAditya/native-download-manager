import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 08: Checksum & Integrity Verifier
class ChecksumVerifierTemplatePage extends StatefulWidget {
  final String title;
  final String? sampleUrl;
  final String? sampleFileName;
  final String? initialHash;
  final String initialAlgo;

  const ChecksumVerifierTemplatePage({
    super.key,
    this.title = '08. Checksum & Integrity Verifier',
    this.sampleUrl,
    this.sampleFileName,
    this.initialHash,
    this.initialAlgo = 'sha256',
  });

  @override
  State<ChecksumVerifierTemplatePage> createState() => _ChecksumVerifierTemplatePageState();
}

class _ChecksumVerifierTemplatePageState extends State<ChecksumVerifierTemplatePage> {
  late final TextEditingController _hashController;
  late String _algo;

  @override
  void initState() {
    super.initState();
    _algo = widget.initialAlgo;
    _hashController = TextEditingController(
      text: widget.initialHash ?? 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  }

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  void _downloadVerifiedFile() async {
    final expectedHash = _hashController.text.trim();
    if (expectedHash.isEmpty) return;

    try {
      await NativeDownloadManager.download(
        url: widget.sampleUrl ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileName: widget.sampleFileName ?? 'Verified_Security_File.pdf',
        checksum: expectedHash,
        checksumAlgorithm: _algo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enqueued download with $_algo hash verification!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red),
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
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Checksum Verification (MD5 / SHA-256)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _algo,
                      decoration: const InputDecoration(labelText: 'Hash Algorithm', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'sha256', child: Text('SHA-256')),
                        DropdownMenuItem(value: 'md5', child: Text('MD5')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _algo = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hashController,
                      decoration: const InputDecoration(labelText: 'Expected Hash String', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _downloadVerifiedFile,
                      icon: const Icon(Icons.shield_rounded),
                      label: const Text('Download & Verify Checksum'),
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
