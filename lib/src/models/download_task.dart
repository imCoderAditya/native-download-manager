import 'dart:async';
import 'package:native_download_manager/src/models/download_models.dart';
import 'package:native_download_manager/src/manager.dart';

/// Represents an active or completed download task.
/// Provides control methods (pause, resume, cancel, retry, delete) and status/progress streams.
class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String? filePath;
  final DownloadStatus status;
  final DownloadProgress progress;
  final String? error;

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    this.filePath,
    required this.status,
    required this.progress,
    this.error,
  });

  /// Stream of progress updates for this specific task.
  /// Completes automatically when progress reaches 100%.
  Stream<DownloadProgress> get progressStream async* {
    await for (final progress in NativeDownloadManager()
        .progressStream
        .where((p) => p.taskId == id)) {
      yield progress;
      if (progress.downloadedBytes > 0 &&
          progress.totalBytes > 0 &&
          progress.downloadedBytes >= progress.totalBytes) {
        break;
      }
    }
  }

  /// Stream of task updates (status, error, file path changes) for this specific task.
  /// Completes automatically after emitting a terminal status (completed, failed, canceled).
  Stream<DownloadTask> get statusStream async* {
    await for (final task
        in NativeDownloadManager().statusStream.where((t) => t.id == id)) {
      yield task;
      if (task.status == DownloadStatus.completed ||
          task.status == DownloadStatus.failed ||
          task.status == DownloadStatus.canceled) {
        break;
      }
    }
  }

  /// Pauses the download.
  Future<void> pause() async {
    await NativeDownloadManager().pause(id);
  }

  /// Resumes the paused download.
  Future<void> resume() async {
    await NativeDownloadManager().resume(id);
  }

  /// Cancels the download task.
  Future<void> cancel() async {
    await NativeDownloadManager().cancel(id);
  }

  /// Retries the failed download task.
  Future<void> retry() async {
    await NativeDownloadManager().retry(id);
  }

  /// Deletes the task from the download history and optionally deletes the file.
  Future<void> delete({bool deleteFile = true}) async {
    await NativeDownloadManager().delete(id, deleteFile: deleteFile);
  }

  @override
  String toString() {
    return 'DownloadTask(id: $id, fileName: $fileName, status: $status, progress: ${progress.percentage.toStringAsFixed(1)}%, error: $error)';
  }
}
