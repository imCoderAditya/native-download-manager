import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:native_download_manager/src/native_api.g.dart';
import 'package:native_download_manager/src/models/download_models.dart';
import 'package:native_download_manager/src/models/download_task.dart';

class _FlutterApiHandler implements NativeDownloadManagerFlutterApi {
  final StreamController<DownloadTask> statusController;
  final StreamController<DownloadProgress> progressController;

  _FlutterApiHandler({
    required this.statusController,
    required this.progressController,
  });

  @override
  void onTaskStatusChanged(PigeonDownloadTask task) {
    statusController.add(NativeDownloadManager.mapPigeonTask(task));
  }

  @override
  void onTaskProgressUpdated(
    String taskId,
    int downloadedBytes,
    int totalBytes,
    double speed,
    int etaSeconds,
  ) {
    progressController.add(
      DownloadProgress(
        taskId: taskId,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        speed: speed,
        etaSeconds: etaSeconds,
      ),
    );
  }
}

/// The main entry point for the Native Download Manager plugin.
class NativeDownloadManager {
  static final NativeDownloadManager _instance = NativeDownloadManager._internal();

  factory NativeDownloadManager() => _instance;

  NativeDownloadManager._internal() {
    _initApi();
  }

  final NativeDownloadManagerHostApi _hostApi = NativeDownloadManagerHostApi();
  final StreamController<DownloadTask> _statusController = StreamController<DownloadTask>.broadcast();
  final StreamController<DownloadProgress> _progressController = StreamController<DownloadProgress>.broadcast();
  bool _isInitialized = false;

  /// Stream of all status changes for all tasks.
  Stream<DownloadTask> get statusStream => _statusController.stream;

  /// Stream of all progress updates for all tasks.
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  void _initApi() {
    if (_isInitialized) return;
    NativeDownloadManagerFlutterApi.setup(
      _FlutterApiHandler(
        statusController: _statusController,
        progressController: _progressController,
      ),
    );
    _hostApi.initialize();
    _isInitialized = true;
  }

  /// Starts a new download task.
  /// 
  /// Returns a [DownloadTask] which can be used to monitor and control the download.
  static Future<DownloadTask> download({
    required String url,
    required String fileName,
    String? destinationDirectory,
    Map<String, String> headers = const {},
    Map<String, String> cookies = const {},
    DownloadPriority priority = DownloadPriority.normal,
    List<NetworkConstraint> networkConstraints = const [],
    String? checksum,
    String? checksumAlgorithm,
    bool overwrite = true,
  }) async {
    final manager = NativeDownloadManager();
    manager._initApi();

    // Compile headers and cookies together if needed or pass cookies in headers
    final mergedHeaders = Map<String, String>.from(headers);
    if (cookies.isNotEmpty) {
      final cookieString = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      mergedHeaders['Cookie'] = cookieString;
    }

    final id = const Uuid().v4();

    final request = PigeonDownloadRequest(
      id: id,
      url: url,
      fileName: fileName,
      destinationDirectory: destinationDirectory,
      headers: mergedHeaders,
      priority: priority.index,
      wifiOnly: networkConstraints.contains(NetworkConstraint.wifiOnly),
      chargingOnly: networkConstraints.contains(NetworkConstraint.chargingOnly),
      requiresBatteryNotLow: networkConstraints.contains(NetworkConstraint.cellularRestricted),
      checksum: checksum,
      checksumAlgorithm: checksumAlgorithm,
      overwrite: overwrite,
    );

    await manager._hostApi.startDownload(request);

    final initialTask = DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      filePath: null,
      status: DownloadStatus.enqueued,
      progress: DownloadProgress(
        taskId: id,
        downloadedBytes: 0,
        totalBytes: 0,
        speed: 0.0,
        etaSeconds: -1,
      ),
    );

    return initialTask;
  }

  /// Pauses a download task.
  Future<void> pause(String taskId) async {
    await _hostApi.pauseDownload(taskId);
  }

  /// Resumes a paused download task.
  Future<void> resume(String taskId) async {
    await _hostApi.resumeDownload(taskId);
  }

  /// Cancels a download task.
  Future<void> cancel(String taskId) async {
    await _hostApi.cancelDownload(taskId);
  }

  /// Retries a failed download task.
  Future<void> retry(String taskId) async {
    await _hostApi.retryDownload(taskId);
  }

  /// Deletes a download task from history.
  /// 
  /// If [deleteFile] is true, the downloaded file is also deleted from disk.
  Future<void> delete(String taskId, {bool deleteFile = true}) async {
    await _hostApi.deleteDownload(taskId, deleteFile);
  }

  /// Retrieves all downloads currently managed by the package (running, paused, completed, etc.).
  Future<List<DownloadTask>> downloads() async {
    final list = await _hostApi.getAllTasks();
    return list.whereType<PigeonDownloadTask>().map(mapPigeonTask).toList();
  }

  /// Clears download history from the database (leaves completed downloads' files intact).
  Future<void> clearHistory() async {
    await _hostApi.clearHistory();
  }

  /// Sets the concurrency limit for active parallel downloads (only applies to Android native execution queue).
  Future<void> setConcurrencyLimit(int limit) async {
    await _hostApi.setConcurrencyLimit(limit);
  }

  /// Utility to map Pigeon auto-generated model to user-facing model.
  static DownloadTask mapPigeonTask(PigeonDownloadTask task) {
    return DownloadTask(
      id: task.id,
      url: task.url,
      fileName: task.fileName,
      filePath: task.filePath,
      status: DownloadStatus.fromInt(task.status),
      error: task.error,
      progress: DownloadProgress(
        taskId: task.id,
        downloadedBytes: task.downloadedBytes,
        totalBytes: task.totalBytes,
        speed: task.speed,
        etaSeconds: task.etaSeconds,
      ),
    );
  }
}
