

/// Status of the download task.
enum DownloadStatus {
  enqueued,
  downloading,
  paused,
  completed,
  failed,
  canceled;

  static DownloadStatus fromInt(int index) {
    if (index >= 0 && index < DownloadStatus.values.length) {
      return DownloadStatus.values[index];
    }
    return DownloadStatus.failed;
  }

  int get toInt => index;
}

/// Priority of the download task.
enum DownloadPriority {
  low,
  normal,
  high;

  static DownloadPriority fromInt(int index) {
    if (index >= 0 && index < DownloadPriority.values.length) {
      return DownloadPriority.values[index];
    }
    return DownloadPriority.normal;
  }

  int get toInt => index;
}

/// Network constraint for a download.
enum NetworkConstraint {
  none,
  wifiOnly,
  cellularRestricted,
  chargingOnly,
}

/// Represents real-time download progress details.
class DownloadProgress {
  final String taskId;
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // Bytes per second
  final int etaSeconds;

  const DownloadProgress({
    required this.taskId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    required this.etaSeconds,
  });

  /// Download percentage (0.0 to 100.0).
  double get percentage {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes) * 100.0;
  }

  /// Formatted speed string (e.g., "1.2 MB/s", "450 KB/s")
  String get formattedSpeed {
    if (speed < 1024) return '${speed.toStringAsFixed(1)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Formatted ETA string (e.g., "01:34", "12s", "calculating...")
  String get formattedEta {
    if (etaSeconds < 0 || totalBytes == 0) return '--:--';
    if (etaSeconds < 60) return '${etaSeconds}s';
    final minutes = etaSeconds ~/ 60;
    final seconds = etaSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted downloaded and total size (e.g., "15.4 MB / 100.0 MB")
  String get formattedSizeRatio {
    return '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() {
    return 'DownloadProgress(taskId: $taskId, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes, speed: $formattedSpeed, eta: $formattedEta)';
  }
}

/// Represents the request to start a download task.
class DownloadRequest {
  final String url;
  final String fileName;
  final String? destinationDirectory;
  final Map<String, String> headers;
  final Map<String, String> cookies;
  final DownloadPriority priority;
  final List<NetworkConstraint> networkConstraints;
  final String? checksum;
  final String? checksumAlgorithm; // "md5" or "sha256"
  final bool overwrite;

  const DownloadRequest({
    required this.url,
    required this.fileName,
    this.destinationDirectory,
    this.headers = const {},
    this.cookies = const {},
    this.priority = DownloadPriority.normal,
    this.networkConstraints = const [],
    this.checksum,
    this.checksumAlgorithm,
    this.overwrite = true,
  });

  bool get wifiOnly => networkConstraints.contains(NetworkConstraint.wifiOnly);
  bool get chargingOnly => networkConstraints.contains(NetworkConstraint.chargingOnly);
  bool get requiresBatteryNotLow => networkConstraints.contains(NetworkConstraint.cellularRestricted); // Maps cellular restriction/etc.
}

/// A download exception representation.
class DownloadException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const DownloadException(this.message, {this.code, this.details});

  @override
  String toString() => 'DownloadException: [$code] $message';
}

/// Represents the final result of a completed download.
class DownloadResult {
  final String taskId;
  final String filePath;
  final bool success;
  final String? error;

  const DownloadResult({
    required this.taskId,
    required this.filePath,
    required this.success,
    this.error,
  });
}

/// Represents historic information about a past download task.
class DownloadHistory {
  final String taskId;
  final String url;
  final String fileName;
  final String? filePath;
  final DownloadStatus status;
  final int totalBytes;
  final DateTime timestamp;

  const DownloadHistory({
    required this.taskId,
    required this.url,
    required this.fileName,
    this.filePath,
    required this.status,
    required this.totalBytes,
    required this.timestamp,
  });
}
