import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 06: Priority Queue Scheduler
class PriorityQueueTemplatePage extends StatefulWidget {
  final String title;
  final String? sampleUrl;
  final String? sampleFileName;

  const PriorityQueueTemplatePage({
    super.key,
    this.title = '06. Priority Queue Scheduler',
    this.sampleUrl,
    this.sampleFileName,
  });

  @override
  State<PriorityQueueTemplatePage> createState() => _PriorityQueueTemplatePageState();
}

class _PriorityQueueTemplatePageState extends State<PriorityQueueTemplatePage> {
  DownloadPriority _selectedPriority = DownloadPriority.high;

  void _enqueuePriorityTask() async {
    final url = widget.sampleUrl ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    final baseName = widget.sampleFileName ?? 'Priority_Task';
    final name = '${baseName}_${_selectedPriority.name}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';

    await NativeDownloadManager.download(
      url: url,
      fileName: name,
      priority: _selectedPriority,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enqueued $name with ${_selectedPriority.name.toUpperCase()} priority!')),
    );
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
                    const Text('Select Task Priority Level:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<DownloadPriority>(
                      segments: const [
                        ButtonSegment(value: DownloadPriority.high, label: Text('High Priority')),
                        ButtonSegment(value: DownloadPriority.normal, label: Text('Normal')),
                        ButtonSegment(value: DownloadPriority.low, label: Text('Low')),
                      ],
                      selected: {_selectedPriority},
                      onSelectionChanged: (set) => setState(() => _selectedPriority = set.first),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _enqueuePriorityTask,
                      icon: const Icon(Icons.low_priority_rounded),
                      label: const Text('Schedule Priority Download'),
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
