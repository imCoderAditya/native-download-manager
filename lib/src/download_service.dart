import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Reusable App Download Helper Service.
class AppDownloadService {
  /// Simple file download helper with callbacks.
  static Future<DownloadTask?> downloadFile({
    required String url,
    required String fileName,
    String? destinationDirectory,
    Map<String, String> headers = const {},
    DownloadPriority priority = DownloadPriority.normal,
    bool overwrite = true,
    void Function(DownloadProgress progress)? onProgress,
    void Function(DownloadTask task)? onStatusChanged,
    void Function(String filePath)? onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      final task = await NativeDownloadManager.download(
        url: url,
        fileName: fileName,
        destinationDirectory: destinationDirectory,
        headers: headers,
        priority: priority,
        overwrite: overwrite,
      );

      task.progressStream.listen(
        (progress) {
          onProgress?.call(progress);
        },
        onError: (err) {
          onError?.call(err.toString());
        },
      );

      task.statusStream.listen(
        (updatedTask) {
          onStatusChanged?.call(updatedTask);

          if (updatedTask.status == DownloadStatus.completed) {
            onSuccess?.call(updatedTask.filePath ?? '');
          } else if (updatedTask.status == DownloadStatus.failed) {
            onError?.call(updatedTask.error ?? 'Download failed.');
          }
        },
        onError: (err) {
          onError?.call(err.toString());
        },
      );

      return task;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }
  }

  /// Displays standalone Active & Recent Downloads Dialog.
  static void showDownloadsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.folder_special_rounded, color: Colors.teal),
              SizedBox(width: 10),
              Text('Active & Recent Downloads',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SizedBox(
            width: double.maxFinite,
            height: 350,
            child: RecentDownloadsDialogList(showRecent: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Downloads file while displaying a Progress Dialog.
  static Future<bool> downloadWithDialog({
    required BuildContext context,
    required String url,
    required String fileName,
    String? destinationDirectory,
    Map<String, String> headers = const {},
    DownloadPriority priority = DownloadPriority.high,
    bool overwrite = true,
    String dialogTitle = 'Downloading File...',
    bool showRecent = false,
  }) async {
    final Completer<bool> completer = Completer<bool>();

    // 1. Show the downloads dialog
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cloud_download_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: showRecent ? 350 : 160,
            child: RecentDownloadsDialogList(
              showRecent: showRecent,
              currentFileName: fileName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    // 2. Trigger the download task
    await downloadFile(
      url: url,
      fileName: fileName,
      destinationDirectory: destinationDirectory,
      headers: headers,
      priority: priority,
      overwrite: overwrite,
      onSuccess: (path) {
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (err) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }
}

/// Embedded Active & Recent Downloads List Widget.
class RecentDownloadsDialogList extends StatefulWidget {
  final bool showRecent;
  final String? currentFileName;

  const RecentDownloadsDialogList({
    super.key,
    this.showRecent = true,
    this.currentFileName,
  });

  @override
  State<RecentDownloadsDialogList> createState() =>
      _RecentDownloadsDialogListState();
}

class _RecentDownloadsDialogListState extends State<RecentDownloadsDialogList> {
  List<DownloadTask> _recentTasks = [];
  late StreamSubscription<DownloadTask> _statusSub;
  late StreamSubscription<DownloadProgress> _progressSub;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _statusSub = NativeDownloadManager().statusStream.listen((_) {
      _loadTasks();
    });

    _progressSub = NativeDownloadManager().progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          final index = _recentTasks.indexWhere((t) => t.id == progress.taskId);
          if (index != -1) {
            final t = _recentTasks[index];
            _recentTasks[index] = DownloadTask(
              id: t.id,
              url: t.url,
              fileName: t.fileName,
              filePath: t.filePath,
              status: t.status,
              progress: progress,
              error: t.error,
            );
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

  Future<void> _loadTasks() async {
    final tasks = await NativeDownloadManager().downloads();

    final filtered = tasks.where((t) {
      if (!widget.showRecent) {
        if (widget.currentFileName != null &&
            widget.currentFileName!.isNotEmpty) {
          return t.fileName == widget.currentFileName;
        }
        return t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.paused;
      }
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _recentTasks = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recentTasks.isEmpty) {
      return const Center(
        child: Text(
          'Downloading...',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _recentTasks.length,
      itemBuilder: (context, index) {
        final task = _recentTasks[index];
        final isDownloading = task.status == DownloadStatus.downloading;
        final isPaused = task.status == DownloadStatus.paused;
        final isFailed = task.status == DownloadStatus.failed ||
            task.status == DownloadStatus.canceled;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      task.fileName.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildBadge(task.status),
                  ],
                ),
                if (isDownloading || isPaused) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress.percentage > 0
                        ? (task.progress.percentage / 100.0)
                        : null,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${task.progress.percentage.toStringAsFixed(0)}%  (${task.progress.formattedSizeRatio})',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        task.progress.formattedSpeed,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isDownloading)
                      IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        tooltip: 'Pause',
                        onPressed: () => task.pause(),
                      ),
                    if (isPaused)
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        tooltip: 'Resume',
                        onPressed: () => task.resume(),
                      ),
                    if (isFailed)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Retry',
                        onPressed: () => task.retry(),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.redAccent),
                      tooltip: 'Delete',
                      onPressed: () async {
                        await task.delete(deleteFile: true);
                        _loadTasks();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(DownloadStatus status) {
    Color col;
    switch (status) {
      case DownloadStatus.downloading:
        col = Colors.blue;
        break;
      case DownloadStatus.completed:
        col = Colors.green;
        break;
      case DownloadStatus.paused:
        col = Colors.orange;
        break;
      case DownloadStatus.failed:
        col = Colors.red;
        break;
      case DownloadStatus.canceled:
        col = Colors.grey;
        break;
      default:
        col = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: col.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 9, color: col, fontWeight: FontWeight.bold),
      ),
    );
  }
}
