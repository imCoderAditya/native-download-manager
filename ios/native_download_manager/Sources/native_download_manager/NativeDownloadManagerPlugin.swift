import Flutter
import UIKit

public class NativeDownloadManagerPlugin: NSObject, FlutterPlugin, NativeDownloadManagerHostApi {
  
  private var manager = DownloadManager.shared
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeDownloadManagerPlugin()
    
    // Set up Pigeon Host API
    NativeDownloadManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    
    // Set up Pigeon Flutter API
    let flutterApi = NativeDownloadManagerFlutterApi(binaryMessenger: registrar.messenger())
    DownloadManager.shared.flutterApi = flutterApi
    
    registrar.addMethodCallDelegate(instance, channel: FlutterMethodChannel(name: "native_download_manager_dummy", binaryMessenger: registrar.messenger()))
  }
  
  // NativeDownloadManagerHostApi protocols
  func initialize() {
    // Explicit initialization hook
  }
  
  func startDownload(request: PigeonDownloadRequest) {
    manager.startDownload(request: request)
  }
  
  func pauseDownload(taskId: String) {
    manager.pauseDownload(taskId: taskId)
  }
  
  func resumeDownload(taskId: String) {
    manager.resumeDownload(taskId: taskId)
  }
  
  func cancelDownload(taskId: String) {
    manager.cancelDownload(taskId: taskId)
  }
  
  func retryDownload(taskId: String) {
    manager.retryDownload(taskId: taskId)
  }
  
  func deleteDownload(taskId: String, deleteFile: Bool) {
    manager.deleteDownload(taskId: taskId, deleteFile: deleteFile)
  }
  
  func getAllTasks() -> [PigeonDownloadTask] {
    return manager.getAllTasks()
  }
  
  func getTask(taskId: String) -> PigeonDownloadTask? {
    return manager.getTask(taskId: taskId)
  }
  
  func clearHistory() {
    manager.clearHistory()
  }
  
  func setConcurrencyLimit(limit: Int64) {
    // iOS manages concurrent downloads automatically on background URLSession, 
    // but we can set HTTPMaximumConnectionsPerHost on a configuration if needed.
  }
}
