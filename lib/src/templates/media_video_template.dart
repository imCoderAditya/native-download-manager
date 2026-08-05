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
  void _downloadVideo(Map<String, String> video) async {
    final url = video['url'] ?? '';
    final filename = video['filename'] ?? 'video.mp4';
    if (url.isEmpty) return;

    AppDownloadService.startDownload(
      url: url,
      fileName: filename,
      priority: DownloadPriority.high,
    );
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
            AppDownloadService.currentDownloadWidget(
              accentColor: Colors.purple,
              progressBarColor: Colors.purpleAccent,
            ),
            const SizedBox(height: 16),
            const Text('Available Media Files',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.videos.isEmpty
                  ? const Center(
                      child: Text('No video items passed to template.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: widget.videos.length,
                      itemBuilder: (context, index) {
                        final item = widget.videos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.video_library_rounded,
                                  color: Colors.white),
                            ),
                            title: Text(
                                item['title'] ??
                                    item['filename'] ??
                                    'Media File',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(item['filename'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.download_for_offline_rounded,
                                  color: Colors.purple,
                                  size: 28),
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
}
