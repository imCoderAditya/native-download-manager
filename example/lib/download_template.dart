import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// ============================================================================
/// 🚀 DIRECT COPY-PASTE DOWNLOAD TEMPLATE FOR ANY FLUTTER PROJECT
///
/// Features:
/// 1. `EasyDownloader.download(...)` - Background download with callbacks.
/// 2. `EasyDownloader.downloadWithDialog(...)` - Download dialog WITH Active & Recent Downloads list.
/// 3. `EasyDownloader.showDownloadsDialog(...)` - Standalone Active & Recent Downloads dialog.
/// ============================================================================

/// Reusable Plug-and-Play Download Service
class EasyDownloader {
  /// Starts a download task with callbacks for progress, status, completion, and error.
  static Future<DownloadTask?> download({
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

      // Listen to real-time progress
      task.progressStream.listen(
        (progress) {
          onProgress?.call(progress);
        },
        onError: (err) {
          onError?.call(err.toString());
        },
      );

      // Listen to status changes & terminal state closure
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

  /// Opens a standalone Dialog showing all Active & Recent Downloads.
  static Future<void> showDownloadsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.folder_zip_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Active & Recent Downloads',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.grey,
                ),
                tooltip: 'Clear History',
                onPressed: () async {
                  await NativeDownloadManager().clearHistory();
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: const RecentDownloadsDialogList(),
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

  /// Downloads a file while displaying a Dialog WITH Active & Recent Downloads list.
  static Future<bool> downloadWithDialog({
    required BuildContext context,
    required String url,
    required String fileName,
    Map<String, String> headers = const {},
    DownloadPriority priority = DownloadPriority.high,
    bool overwrite = true,
    String dialogTitle = 'Downloading File...',
  }) async {
    final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
    final ValueNotifier<String> speedNotifier = ValueNotifier<String>('');
    final ValueNotifier<bool> isCompletedNotifier = ValueNotifier<bool>(false);
    final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.cloud_download_rounded, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dialogTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<double>(
                      valueListenable: progressNotifier,
                      builder: (context, val, _) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: val > 0 ? (val / 100.0) : null,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${val.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                ValueListenableBuilder<String>(
                                  valueListenable: speedNotifier,
                                  builder: (context, speed, _) {
                                    return Text(
                                      speed,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: errorNotifier,
                      builder: (context, err, _) {
                        if (err == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            err,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Active & Recent Downloads',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 220,
                      child: RecentDownloadsDialogList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: isCompletedNotifier,
                builder: (context, isDone, _) {
                  return TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isDone ? 'Close' : 'Dismiss'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    final Completer<bool> completer = Completer<bool>();

    await download(
      url: url,
      fileName: fileName,
      headers: headers,
      priority: priority,
      overwrite: overwrite,
      onProgress: (p) {
        progressNotifier.value = p.percentage.clamp(0.0, 100.0);
        speedNotifier.value = '${p.formattedSpeed}  (${p.formattedSizeRatio})';
      },
      onSuccess: (path) {
        progressNotifier.value = 100.0;
        isCompletedNotifier.value = true;
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (err) {
        errorNotifier.value = err;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }
}

/// ============================================================================
/// 📋 REUSABLE DIALOG CONTENT LIST FOR ACTIVE & RECENT DOWNLOADS
/// ============================================================================
class RecentDownloadsDialogList extends StatefulWidget {
  const RecentDownloadsDialogList({super.key});

  @override
  State<RecentDownloadsDialogList> createState() =>
      _RecentDownloadsDialogListState();
}

class _RecentDownloadsDialogListState extends State<RecentDownloadsDialogList> {
  List<DownloadTask> _tasks = [];
  late StreamSubscription<DownloadTask> _statusSub;
  late StreamSubscription<DownloadProgress> _progressSub;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _statusSub = NativeDownloadManager().statusStream.listen((_) {
      _loadTasks();
    });

    _progressSub = NativeDownloadManager().progressStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _progressSub.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final list = await NativeDownloadManager().downloads();
    if (mounted) {
      setState(() {
        _tasks = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return Center(
        child: Text(
          'No recent downloads.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildDialogTaskTile(task);
      },
    );
  }

  Widget _buildDialogTaskTile(DownloadTask task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case DownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.downloading:
        statusColor = Colors.blue;
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_rounded;
        break;
      case DownloadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_rounded;
        break;
      case DownloadStatus.canceled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.purple;
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      task.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (task.status == DownloadStatus.downloading)
                IconButton(
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await task.pause();
                    _loadTasks();
                  },
                ),
              if (task.status == DownloadStatus.paused)
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await task.resume();
                    _loadTasks();
                  },
                ),
              if (task.status == DownloadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await task.retry();
                    _loadTasks();
                  },
                ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  await task.delete(deleteFile: true);
                  _loadTasks();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<DownloadProgress>(
            stream: task.progressStream,
            initialData: task.progress,
            builder: (context, snapshot) {
              final p = snapshot.data ?? task.progress;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.percentage > 0 ? (p.percentage / 100.0) : null,
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p.percentage.toStringAsFixed(0)}% (${p.formattedSizeRatio})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (task.status == DownloadStatus.downloading)
                        Text(
                          p.formattedSpeed,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 📱 COMPLETE COPY-PASTEABLE DOWNLOAD MANAGER SCREEN TEMPLATE
/// ============================================================================
class DownloadTemplatePage extends StatefulWidget {
  const DownloadTemplatePage({super.key});

  @override
  State<DownloadTemplatePage> createState() => _DownloadTemplatePageState();
}

class _DownloadTemplatePageState extends State<DownloadTemplatePage> {
  final TextEditingController _urlController = TextEditingController(
    text:
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  );
  final TextEditingController _fileNameController = TextEditingController(
    text: 'SampleDocument.pdf',
  );

  List<DownloadTask> _downloadsList = [];
  late StreamSubscription<DownloadTask> _globalStatusSub;
  late StreamSubscription<DownloadProgress> _globalProgressSub;

  @override
  void initState() {
    super.initState();
    _refreshDownloads();

    _globalStatusSub = NativeDownloadManager().statusStream.listen((_) {
      _refreshDownloads();
    });

    _globalProgressSub = NativeDownloadManager().progressStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _globalStatusSub.cancel();
    _globalProgressSub.cancel();
    _urlController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _refreshDownloads() async {
    final tasks = await NativeDownloadManager().downloads();
    if (mounted) {
      setState(() {
        _downloadsList = tasks;
      });
    }
  }

  void _startBackgroundDownload() async {
    final url = _urlController.text.trim();
    final fileName = _fileNameController.text.trim();

    if (url.isEmpty || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid URL & filename')),
      );
      return;
    }

    await EasyDownloader.download(
      url: url,
      fileName: fileName,
      onSuccess: (filePath) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download Complete: $fileName')));
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      },
    );

    _refreshDownloads();
  }

  void _startDialogDownload() async {
    final url = _urlController.text.trim();
    final fileName = _fileNameController.text.trim();

    if (url.isEmpty || fileName.isEmpty) return;

    final success = await EasyDownloader.downloadWithDialog(
      context: context,
      url: url,
      fileName: fileName,
      dialogTitle: 'Downloading $fileName',
    );

    if (success) {
      _refreshDownloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Manager Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_rounded),
            tooltip: 'View Active & Recent Downloads',
            onPressed: () {
              EasyDownloader.showDownloadsDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDownloads,
            tooltip: 'Refresh Queue',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              await NativeDownloadManager().clearHistory();
              _refreshDownloads();
            },
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL Input Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Download Config',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'File Download URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                        labelText: 'Save Filename (with extension)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startDialogDownload,
                            icon: const Icon(Icons.picture_in_picture_rounded),
                            label: const Text('Download (With Dialog)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _startBackgroundDownload,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Background'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Active & Recent Downloads',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Downloads List
            Expanded(
              child: _downloadsList.isEmpty
                  ? Center(
                      child: Text(
                        'No download tasks found.\nStart a download above!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _downloadsList.length,
                      itemBuilder: (context, index) {
                        final task = _downloadsList[index];
                        return _buildTaskCard(task);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(DownloadTask task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case DownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.downloading:
        statusColor = Colors.blue;
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_rounded;
        break;
      case DownloadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_rounded;
        break;
      case DownloadStatus.canceled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.purple;
        statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        task.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.status == DownloadStatus.downloading)
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    onPressed: () async {
                      await task.pause();
                      _refreshDownloads();
                    },
                  ),
                if (task.status == DownloadStatus.paused)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () async {
                      await task.resume();
                      _refreshDownloads();
                    },
                  ),
                if (task.status == DownloadStatus.failed)
                  IconButton(
                    icon: const Icon(Icons.replay_rounded),
                    onPressed: () async {
                      await task.retry();
                      _refreshDownloads();
                    },
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    await task.delete(deleteFile: true);
                    _refreshDownloads();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<DownloadProgress>(
              stream: task.progressStream,
              initialData: task.progress,
              builder: (context, snapshot) {
                final p = snapshot.data ?? task.progress;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: p.percentage > 0 ? (p.percentage / 100.0) : null,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.percentage.toStringAsFixed(0)}%  (${p.formattedSizeRatio})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (task.status == DownloadStatus.downloading)
                          Text(
                            '${p.formattedSpeed}  |  ETA: ${p.formattedEta}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
