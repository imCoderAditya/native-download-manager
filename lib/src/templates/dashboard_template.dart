import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 01: Downloads Dashboard & Active Tasks Hub
class DashboardTemplatePage extends StatefulWidget {
  final String title;
  final String? defaultUrl;
  final String? defaultFileName;

  const DashboardTemplatePage({
    super.key,
    this.title = '01. Downloads Dashboard',
    this.defaultUrl,
    this.defaultFileName,
  });

  @override
  State<DashboardTemplatePage> createState() => _DashboardTemplatePageState();
}

class _DashboardTemplatePageState extends State<DashboardTemplatePage> {
  List<DownloadTask> _tasks = [];
  late StreamSubscription<DownloadTask> _statusSub;
  late StreamSubscription<DownloadProgress> _progressSub;

  late final TextEditingController _optionalUrlController;
  late final TextEditingController _optionalFileNameController;

  @override
  void initState() {
    super.initState();
    _optionalUrlController = TextEditingController(
      text: widget.defaultUrl ?? 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    );
    _optionalFileNameController = TextEditingController(
      text: widget.defaultFileName ?? 'sample_video.mp4',
    );

    _refresh();

    _statusSub = NativeDownloadManager().statusStream.listen((_) {
      _refresh();
    });

    _progressSub = NativeDownloadManager().progressStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _progressSub.cancel();
    _optionalUrlController.dispose();
    _optionalFileNameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await NativeDownloadManager().downloads();
    if (mounted) setState(() => _tasks = list);
  }

  void _startCustomDownload() async {
    final url = _optionalUrlController.text.trim().isNotEmpty
        ? _optionalUrlController.text.trim()
        : (widget.defaultUrl ?? 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    final fileName = _optionalFileNameController.text.trim().isNotEmpty
        ? _optionalFileNameController.text.trim()
        : (widget.defaultFileName ?? 'sample_video.mp4');

    await NativeDownloadManager.download(
      url: url,
      fileName: fileName,
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.enqueued).toList();
    final completedTasks = _tasks.where((t) => t.status == DownloadStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Summary Row
            Row(
              children: [
                _buildStatCard('Active', activeTasks.length.toString(), Colors.blue, Icons.downloading_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Completed', completedTasks.length.toString(), Colors.green, Icons.check_circle_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Total Tasks', _tasks.length.toString(), Colors.purple, Icons.folder_zip_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Optional URL Input Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Download Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _optionalUrlController,
                      decoration: const InputDecoration(
                        hintText: 'URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _optionalFileNameController,
                      decoration: const InputDecoration(
                        hintText: 'Filename',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startCustomDownload,
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Start Download'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Active Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            if (activeTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No active downloads running.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...activeTasks.map((t) => _buildTaskItem(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(DownloadTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(task.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: StreamBuilder<DownloadProgress>(
          stream: task.progressStream,
          initialData: task.progress,
          builder: (context, snapshot) {
            final p = snapshot.data ?? task.progress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                LinearProgressIndicator(value: p.percentage > 0 ? p.percentage / 100 : null),
                const SizedBox(height: 4),
                Text('${p.percentage.toStringAsFixed(0)}% • ${p.formattedSpeed} • ${p.formattedSizeRatio}', style: const TextStyle(fontSize: 11)),
              ],
            );
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.pause_rounded, color: Colors.orange),
          onPressed: () async {
            await task.pause();
            _refresh();
          },
        ),
      ),
    );
  }
}
