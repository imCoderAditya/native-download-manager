import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/native_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/native/download/manager/native_download_manager/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: "com.native_download_manager"),
  swiftOut: 'ios/native_download_manager/Sources/native_download_manager/Messages.g.swift',
  swiftOptions: SwiftOptions(),
))

class PigeonDownloadRequest {
  late String id;
  late String url;
  late String fileName;
  String? destinationDirectory;
  late Map<String?, String?> headers;
  late bool wifiOnly;
  late bool chargingOnly;
  late bool requiresBatteryNotLow;
  late int priority; // 0: low, 1: normal, 2: high
  String? checksum;
  String? checksumAlgorithm; // "md5", "sha256"
  late bool overwrite;
}

class PigeonDownloadTask {
  late String id;
  late String url;
  late String fileName;
  String? filePath;
  late int status; // 0: enqueued, 1: downloading, 2: paused, 3: completed, 4: failed, 5: canceled
  late double progress; // 0.0 to 1.0
  late int downloadedBytes;
  late int totalBytes;
  late double speed; // bytes per second
  late int etaSeconds;
  String? error;
}

@HostApi()
abstract class NativeDownloadManagerHostApi {
  void initialize();
  void startDownload(PigeonDownloadRequest request);
  void pauseDownload(String taskId);
  void resumeDownload(String taskId);
  void cancelDownload(String taskId);
  void retryDownload(String taskId);
  void deleteDownload(String taskId, bool deleteFile);
  List<PigeonDownloadTask> getAllTasks();
  PigeonDownloadTask? getTask(String taskId);
  void clearHistory();
  void setConcurrencyLimit(int limit);
}

@FlutterApi()
abstract class NativeDownloadManagerFlutterApi {
  void onTaskStatusChanged(PigeonDownloadTask task);
  void onTaskProgressUpdated(String taskId, int downloadedBytes, int totalBytes, double speed, int etaSeconds);
}
