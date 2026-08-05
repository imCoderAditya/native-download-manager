import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Reusable App Download Helper Service with Full Customization Support.
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

  /// Triggers a background file download without showing a popup dialog.
  /// Perfect to use inside button onPressed with [currentDownloadWidget] in screen UI!
  static Future<DownloadTask?> startDownload({
    required String url,
    required String fileName,
    String? destinationDirectory,
    Map<String, String> headers = const {},
    DownloadPriority priority = DownloadPriority.high,
    bool overwrite = true,
    void Function(DownloadProgress progress)? onProgress,
    void Function(DownloadTask task)? onStatusChanged,
    void Function(String filePath)? onSuccess,
    void Function(String error)? onError,
  }) async {
    return downloadFile(
      url: url,
      fileName: fileName,
      destinationDirectory: destinationDirectory,
      headers: headers,
      priority: priority,
      overwrite: overwrite,
      onProgress: onProgress,
      onStatusChanged: onStatusChanged,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Displays standalone Active & Recent Downloads Dialog with full customization.
  static void showDownloadsDialog(
    BuildContext context, {
    ShapeBorder? dialogShape,
    Color? dialogBackgroundColor,
    TextStyle? dialogTitleTextStyle,
    String closeButtonText = 'Close',
    Widget? closeButton,
    Color? cardBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? progressBarColor,
    Color? accentColor,
    TextStyle? fileNameTextStyle,
    TextStyle? progressTextStyle,
    TextStyle? speedTextStyle,
    Widget Function(DownloadStatus status)? badgeBuilder,
    Widget Function(String fileName)? iconBuilder,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: dialogShape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: dialogBackgroundColor,
          title: Row(
            children: [
              Icon(Icons.folder_special_rounded,
                  color: accentColor ?? Colors.teal),
              const SizedBox(width: 10),
              Text(
                'Active & Recent Downloads',
                style: dialogTitleTextStyle ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: RecentDownloadsDialogList(
              showRecent: true,
              cardBackgroundColor: cardBackgroundColor,
              borderRadius: borderRadius,
              progressBarColor: progressBarColor,
              accentColor: accentColor,
              fileNameTextStyle: fileNameTextStyle,
              progressTextStyle: progressTextStyle,
              speedTextStyle: speedTextStyle,
              badgeBuilder: badgeBuilder,
              iconBuilder: iconBuilder,
            ),
          ),
          actions: [
            closeButton ??
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(closeButtonText),
                ),
          ],
        );
      },
    );
  }

  /// Downloads file while displaying a Progress Dialog with full customization.
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
    ShapeBorder? dialogShape,
    Color? dialogBackgroundColor,
    TextStyle? dialogTitleTextStyle,
    String closeButtonText = 'Close',
    Widget? closeButton,
    Color? cardBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? progressBarColor,
    Color? accentColor,
    TextStyle? fileNameTextStyle,
    TextStyle? progressTextStyle,
    TextStyle? speedTextStyle,
    Widget Function(DownloadStatus status)? badgeBuilder,
    Widget Function(String fileName)? iconBuilder,
  }) async {
    final Completer<bool> completer = Completer<bool>();

    // 1. Show the downloads dialog
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: dialogShape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: dialogBackgroundColor,
          title: Row(
            children: [
              Icon(Icons.cloud_download_rounded,
                  color: accentColor ?? Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: dialogTitleTextStyle ??
                      const TextStyle(
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
              cardBackgroundColor: cardBackgroundColor,
              borderRadius: borderRadius,
              progressBarColor: progressBarColor,
              accentColor: accentColor,
              fileNameTextStyle: fileNameTextStyle,
              progressTextStyle: progressTextStyle,
              speedTextStyle: speedTextStyle,
              badgeBuilder: badgeBuilder,
              iconBuilder: iconBuilder,
            ),
          ),
          actions: [
            closeButton ??
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(closeButtonText),
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

  /// Returns a standalone Widget displaying ONLY the currently active downloading task in any screen UI.
  static Widget currentDownloadWidget({
    Key? key,
    String? taskId,
    String? fileName,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onCompleted,
    VoidCallback? onCancelled,
    Color? cardBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? progressBarColor,
    Color? accentColor,
    TextStyle? fileNameTextStyle,
    TextStyle? progressTextStyle,
    TextStyle? speedTextStyle,
    Widget Function(DownloadStatus status)? badgeBuilder,
    Widget Function(String fileName)? iconBuilder,
    bool showPauseButton = true,
    bool showResumeButton = true,
    bool showRetryButton = true,
    bool showCancelButton = true,
  }) {
    return CurrentDownloadWidget(
      key: key,
      taskId: taskId,
      fileName: fileName,
      margin: margin,
      padding: padding,
      onCompleted: onCompleted,
      onCancelled: onCancelled,
      cardBackgroundColor: cardBackgroundColor,
      borderRadius: borderRadius,
      progressBarColor: progressBarColor,
      accentColor: accentColor,
      fileNameTextStyle: fileNameTextStyle,
      progressTextStyle: progressTextStyle,
      speedTextStyle: speedTextStyle,
      badgeBuilder: badgeBuilder,
      iconBuilder: iconBuilder,
      showPauseButton: showPauseButton,
      showResumeButton: showResumeButton,
      showRetryButton: showRetryButton,
      showCancelButton: showCancelButton,
    );
  }
}

/// Embedded Active & Recent Downloads List Widget with Full Customization.
class RecentDownloadsDialogList extends StatefulWidget {
  final bool showRecent;
  final String? currentFileName;
  final Color? cardBackgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? progressBarColor;
  final Color? accentColor;
  final TextStyle? fileNameTextStyle;
  final TextStyle? progressTextStyle;
  final TextStyle? speedTextStyle;
  final Widget Function(DownloadStatus status)? badgeBuilder;
  final Widget Function(String fileName)? iconBuilder;
  final bool showPauseButton;
  final bool showResumeButton;
  final bool showRetryButton;
  final bool showDeleteButton;

  const RecentDownloadsDialogList({
    super.key,
    this.showRecent = true,
    this.currentFileName,
    this.cardBackgroundColor,
    this.borderRadius,
    this.progressBarColor,
    this.accentColor,
    this.fileNameTextStyle,
    this.progressTextStyle,
    this.speedTextStyle,
    this.badgeBuilder,
    this.iconBuilder,
    this.showPauseButton = true,
    this.showResumeButton = true,
    this.showRetryButton = true,
    this.showDeleteButton = true,
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

    final accent = widget.accentColor ?? Colors.teal;

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
          color: widget.cardBackgroundColor ??
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    widget.iconBuilder?.call(task.fileName) ??
                        Icon(
                          task.fileName.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.insert_drive_file_rounded,
                          color: accent,
                          size: 20,
                        ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: widget.fileNameTextStyle ??
                            const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    widget.badgeBuilder?.call(task.status) ??
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
                    color: widget.progressBarColor,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${task.progress.percentage.toStringAsFixed(0)}%  (${task.progress.formattedSizeRatio})',
                        style: widget.progressTextStyle ??
                            const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        task.progress.formattedSpeed,
                        style: widget.speedTextStyle ??
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isDownloading && widget.showPauseButton)
                      IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        tooltip: 'Pause',
                        onPressed: () => task.pause(),
                      ),
                    if (isPaused && widget.showResumeButton)
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        tooltip: 'Resume',
                        onPressed: () => task.resume(),
                      ),
                    if (isFailed && widget.showRetryButton)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Retry',
                        onPressed: () => task.retry(),
                      ),
                    if (widget.showDeleteButton)
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

/// Reusable Standalone Widget to display ONLY the currently active downloading task in any screen UI with Full Customization.
class CurrentDownloadWidget extends StatefulWidget {
  final String? taskId;
  final String? fileName;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;
  final Color? cardBackgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? progressBarColor;
  final Color? accentColor;
  final TextStyle? fileNameTextStyle;
  final TextStyle? progressTextStyle;
  final TextStyle? speedTextStyle;
  final Widget Function(DownloadStatus status)? badgeBuilder;
  final Widget Function(String fileName)? iconBuilder;
  final bool showPauseButton;
  final bool showResumeButton;
  final bool showRetryButton;
  final bool showCancelButton;

  const CurrentDownloadWidget({
    super.key,
    this.taskId,
    this.fileName,
    this.margin,
    this.padding,
    this.onCompleted,
    this.onCancelled,
    this.cardBackgroundColor,
    this.borderRadius,
    this.progressBarColor,
    this.accentColor,
    this.fileNameTextStyle,
    this.progressTextStyle,
    this.speedTextStyle,
    this.badgeBuilder,
    this.iconBuilder,
    this.showPauseButton = true,
    this.showResumeButton = true,
    this.showRetryButton = true,
    this.showCancelButton = true,
  });

  @override
  State<CurrentDownloadWidget> createState() => _CurrentDownloadWidgetState();
}

class _CurrentDownloadWidgetState extends State<CurrentDownloadWidget> {
  DownloadTask? _activeTask;
  late StreamSubscription<DownloadTask> _statusSub;
  late StreamSubscription<DownloadProgress> _progressSub;

  @override
  void initState() {
    super.initState();
    _findActiveTask();

    _statusSub = NativeDownloadManager().statusStream.listen((task) {
      if (mounted) {
        if (task.status == DownloadStatus.completed &&
            _activeTask?.id == task.id) {
          widget.onCompleted?.call();
        } else if (task.status == DownloadStatus.canceled &&
            _activeTask?.id == task.id) {
          widget.onCancelled?.call();
        }
        _findActiveTask();
      }
    });

    _progressSub = NativeDownloadManager().progressStream.listen((progress) {
      if (mounted &&
          _activeTask != null &&
          progress.taskId == _activeTask!.id) {
        setState(() {
          _activeTask = DownloadTask(
            id: _activeTask!.id,
            url: _activeTask!.url,
            fileName: _activeTask!.fileName,
            filePath: _activeTask!.filePath,
            status: _activeTask!.status,
            progress: progress,
            error: _activeTask!.error,
          );
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

  Future<void> _findActiveTask() async {
    final tasks = await NativeDownloadManager().downloads();
    DownloadTask? found;

    for (final t in tasks) {
      if (widget.taskId != null && widget.taskId!.isNotEmpty) {
        if (t.id == widget.taskId) {
          found = t;
          break;
        }
      } else if (widget.fileName != null && widget.fileName!.isNotEmpty) {
        if (t.fileName == widget.fileName) {
          found = t;
          break;
        }
      } else {
        if (t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.paused) {
          found = t;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _activeTask = found;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTask == null) {
      return const SizedBox.shrink();
    }

    final task = _activeTask!;
    final isDownloading = task.status == DownloadStatus.downloading;
    final isPaused = task.status == DownloadStatus.paused;
    final isFailed = task.status == DownloadStatus.failed ||
        task.status == DownloadStatus.canceled;
    final accent = widget.accentColor ?? Colors.teal;

    return Card(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: widget.cardBackgroundColor ??
          Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                widget.iconBuilder?.call(task.fileName) ??
                    Icon(
                      task.fileName.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_rounded,
                      color: accent,
                      size: 20,
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.fileName,
                    style: widget.fileNameTextStyle ??
                        const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                widget.badgeBuilder?.call(task.status) ??
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
                color: widget.progressBarColor,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task.progress.percentage.toStringAsFixed(0)}%  (${task.progress.formattedSizeRatio})',
                    style: widget.progressTextStyle ??
                        const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    task.progress.formattedSpeed,
                    style: widget.speedTextStyle ??
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloading && widget.showPauseButton)
                  IconButton(
                    icon: const Icon(Icons.pause_rounded, size: 20),
                    tooltip: 'Pause',
                    onPressed: () => task.pause(),
                  ),
                if (isPaused && widget.showResumeButton)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    tooltip: 'Resume',
                    onPressed: () => task.resume(),
                  ),
                if (isFailed && widget.showRetryButton)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Retry',
                    onPressed: () => task.retry(),
                  ),
                if (widget.showCancelButton)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        size: 20, color: Colors.redAccent),
                    tooltip: 'Cancel',
                    onPressed: () async {
                      await task.cancel();
                      _findActiveTask();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
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
