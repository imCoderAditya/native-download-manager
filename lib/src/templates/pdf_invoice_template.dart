import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 02: PDF & Invoice Downloader
/// Supports Single PDF, Multiple PDFs, and Auto-Start Instant Download on page launch.
class PdfInvoiceTemplatePage extends StatefulWidget {
  final String title;

  /// Optional single PDF item: {'title': '...', 'url': '...', 'filename': '...', 'id': '...', 'size': '...'}
  final Map<String, String>? singlePdf;

  /// Optional single URL shorthand
  final String? url;

  /// Optional single filename shorthand
  final String? fileName;

  /// Optional list for multiple PDF items
  final List<Map<String, String>>? invoices;

  /// If true, automatically starts downloading the PDF immediately as soon as the template screen opens!
  final bool autoStart;

  const PdfInvoiceTemplatePage({
    super.key,
    this.title = 'PDF & Invoice Downloader',
    this.singlePdf,
    this.url,
    this.fileName,
    this.invoices,
    this.autoStart = false,
  });

  @override
  State<PdfInvoiceTemplatePage> createState() => _PdfInvoiceTemplatePageState();
}

class _PdfInvoiceTemplatePageState extends State<PdfInvoiceTemplatePage> {
  bool _hasAutoStarted = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasAutoStarted) return;
        _hasAutoStarted = true;

        final target = _getEffectiveSingle() ??
            (widget.invoices != null && widget.invoices!.isNotEmpty
                ? widget.invoices!.first
                : null);

        if (target != null) {
          _triggerDownload(context, target);
        }
      });
    }
  }

  Map<String, String>? _getEffectiveSingle() {
    if (widget.singlePdf != null) return widget.singlePdf;
    if (widget.url != null && widget.url!.isNotEmpty) {
      return {
        'title': widget.title,
        'url': widget.url!,
        'filename': widget.fileName ?? 'document.pdf',
        'id': 'PDF-SINGLE',
        'size': 'PDF File',
      };
    }
    return null;
  }

  void _triggerDownload(
      BuildContext context, Map<String, String> pdfItem) async {
    final pdfUrl = pdfItem['url'] ?? '';
    final name = pdfItem['filename'] ?? 'document.pdf';
    final dialogTitle = pdfItem['title'] ?? 'Downloading PDF...';

    if (pdfUrl.isEmpty) return;

    await AppDownloadService.downloadWithDialog(
      context: context,
      url: pdfUrl,
      fileName: name,
      dialogTitle: dialogTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSingle = _getEffectiveSingle();
    final isSingleMode = effectiveSingle != null;
    final List<Map<String, String>> effectiveList = widget.invoices ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIVE ACTIVE DOWNLOAD CARD
            AppDownloadService.currentDownloadWidget(),

            // SINGLE PDF HERO CARD
            if (isSingleMode) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        effectiveSingle['title'] ?? 'PDF Document',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Filename: ${effectiveSingle['filename'] ?? "document.pdf"}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (effectiveSingle['size'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Size: ${effectiveSingle['size']}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _triggerDownload(context, effectiveSingle),
                          icon: const Icon(Icons.file_download_rounded),
                          label: const Text('Download PDF Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // MULTIPLE PDF MODE LIST
            if (effectiveList.isNotEmpty) ...[
              if (isSingleMode)
                const Text('Other Invoices',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: effectiveList.length,
                itemBuilder: (context, index) {
                  final item = effectiveList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white),
                      ),
                      title: Text(
                        item['title'] ?? item['filename'] ?? 'PDF Document',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          '${item['id'] ?? 'DOC'} • ${item['size'] ?? 'PDF File'}'),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _triggerDownload(context, item),
                        icon: const Icon(Icons.file_download_rounded, size: 18),
                        label: const Text('Download'),
                      ),
                    ),
                  );
                },
              ),
            ],

            if (!isSingleMode && effectiveList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('No PDF items or URL passed to template.',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
