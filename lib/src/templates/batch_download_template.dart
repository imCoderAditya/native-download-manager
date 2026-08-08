import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 04: Batch & Concurrency Queue Manager (Purely Dynamic Data)
class BatchDownloadTemplatePage extends StatefulWidget {
  final String title;
  final List<String> urls;
  final int initialConcurrencyLimit;

  const BatchDownloadTemplatePage({
    super.key,
    this.title = '04. Batch & Concurrency Manager',
    required this.urls,
    this.initialConcurrencyLimit = 2,
  });

  @override
  State<BatchDownloadTemplatePage> createState() => _BatchDownloadTemplatePageState();
}

class _BatchDownloadTemplatePageState extends State<BatchDownloadTemplatePage> {
  late int _concurrencyLimit;
  List<DownloadTask> _batchTasks = [];
  late StreamSubscription<DownloadTask> _statusSub;
  late StreamSubscription<DownloadProgress> _progressSub;

  @override
  void initState() {
    super.initState();
    _concurrencyLimit = widget.initialConcurrencyLimit;
    _refresh();
    _statusSub = NativeDownloadManager().statusStream.listen((task) {
      if (mounted) {
        setState(() {
          final index = _batchTasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _batchTasks[index] = task;
          } else {
            _batchTasks.insert(0, task);
          }
        });
        _refresh();
      }
    });

    _progressSub = NativeDownloadManager().progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          final index = _batchTasks.indexWhere((t) => t.id == progress.taskId);
          if (index != -1) {
            final t = _batchTasks[index];
            final isComplete = progress.totalBytes > 0 && progress.downloadedBytes >= progress.totalBytes;
            _batchTasks[index] = DownloadTask(
              id: t.id,
              url: t.url,
              fileName: t.fileName,
              filePath: t.filePath,
              status: isComplete ? DownloadStatus.completed : t.status,
              progress: progress,
              error: t.error,
            );
          } else {
            _refresh();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _progressSub.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await NativeDownloadManager().downloads();
    if (mounted) setState(() => _batchTasks = list);
  }

  void _startBatchDownload() async {
    await NativeDownloadManager().setConcurrencyLimit(_concurrencyLimit);

    for (int i = 0; i < widget.urls.length; i++) {
      final url = widget.urls[i];
      final ext = url.contains('.') ? url.split('.').last.split('?').first : 'file';
      await NativeDownloadManager.download(
        url: url,
        fileName: 'batch_file_${i + 1}.$ext',
      );
    }
    _refresh();
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Max Parallel Downloads Limit:', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<int>(
                          value: _concurrencyLimit,
                          items: [1, 2, 3, 5].map((l) => DropdownMenuItem(value: l, child: Text('$l Parallel'))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _concurrencyLimit = val);
                              NativeDownloadManager().setConcurrencyLimit(val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: widget.urls.isEmpty ? null : _startBatchDownload,
                      icon: const Icon(Icons.dynamic_feed_rounded),
                      label: Text('Start Batch Download (${widget.urls.length} Files)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Batch Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: _batchTasks.isEmpty
                  ? const Center(child: Text('No active batch tasks in queue.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _batchTasks.length,
                      itemBuilder: (context, index) {
                        final t = _batchTasks[index];
                        return ListTile(
                          title: Text(t.fileName),
                          subtitle: Text(t.status.name.toUpperCase()),
                          trailing: Text('${t.progress.percentage.toStringAsFixed(0)}%'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
