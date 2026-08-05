import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 03: Large Media & Video Stream Downloader (Purely Dynamic Data)
class MediaVideoTemplatePage extends StatefulWidget {
  final String title;
  final List<Map<String, String>> videos;

  const MediaVideoTemplatePage({
    super.key,
    this.title = '03. Media & Video Downloader',
    required this.videos,
  });

  @override
  State<MediaVideoTemplatePage> createState() => _MediaVideoTemplatePageState();
}

class _MediaVideoTemplatePageState extends State<MediaVideoTemplatePage> {
  DownloadTask? _activeTask;

  void _downloadVideo(Map<String, String> video) async {
    final url = video['url'] ?? '';
    final filename = video['filename'] ?? 'video.mp4';
    if (url.isEmpty) return;

    final task = await NativeDownloadManager.download(
      url: url,
      fileName: filename,
      priority: DownloadPriority.high,
    );

    setState(() {
      _activeTask = task;
    });
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
            if (_activeTask != null) _buildActiveMediaCard(_activeTask!),
            const SizedBox(height: 16),
            const Text('Available Media Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.videos.isEmpty
                  ? const Center(child: Text('No video items passed to template.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: widget.videos.length,
                      itemBuilder: (context, index) {
                        final item = widget.videos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.video_library_rounded, color: Colors.white),
                            ),
                            title: Text(item['title'] ?? item['filename'] ?? 'Media File', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item['filename'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.download_for_offline_rounded, color: Colors.purple, size: 28),
                              onPressed: () => _downloadVideo(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMediaCard(DownloadTask task) {
    return Card(
      elevation: 2,
      color: Colors.purple.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.movie_rounded, color: Colors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(task.status.name.toUpperCase(), style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<DownloadProgress>(
              stream: task.progressStream,
              initialData: task.progress,
              builder: (context, snapshot) {
                final p = snapshot.data ?? task.progress;
                return Column(
                  children: [
                    LinearProgressIndicator(value: p.percentage > 0 ? p.percentage / 100 : null),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.percentage.toStringAsFixed(0)}% • ${p.formattedSizeRatio}', style: const TextStyle(fontSize: 12)),
                        Text('Speed: ${p.formattedSpeed} | ETA: ${p.formattedEta}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.pause_rounded), onPressed: () => task.pause()),
                IconButton(icon: const Icon(Icons.play_arrow_rounded), onPressed: () => task.resume()),
                IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => task.cancel()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
