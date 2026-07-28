package com.native_download_manager

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin

class NativeDownloadManagerPlugin : FlutterPlugin, NativeDownloadManagerHostApi {
    private var context: Context? = null
    private var controller: DownloadManagerController? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        controller = DownloadManagerController.getInstance(flutterPluginBinding.applicationContext)
        
        // Setup Pigeon Host API
        NativeDownloadManagerHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        
        // Setup Pigeon Flutter API for callbacks
        val flutterApi = NativeDownloadManagerFlutterApi(flutterPluginBinding.binaryMessenger)
        controller?.flutterApi = flutterApi
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NativeDownloadManagerHostApi.setUp(binding.binaryMessenger, null)
        controller?.flutterApi = null
        controller = null
        context = null
    }

    // NativeDownloadManagerHostApi implementations
    override fun initialize() {
        // Initialization is done implicitly on attached, but this acts as an explicit hook.
    }

    override fun startDownload(request: PigeonDownloadRequest) {
        controller?.enqueue(request)
    }

    override fun pauseDownload(taskId: String) {
        controller?.pause(taskId)
    }

    override fun resumeDownload(taskId: String) {
        controller?.resume(taskId)
    }

    override fun cancelDownload(taskId: String) {
        controller?.cancel(taskId)
    }

    override fun retryDownload(taskId: String) {
        controller?.retry(taskId)
    }

    override fun deleteDownload(taskId: String, deleteFile: Boolean) {
        controller?.delete(taskId, deleteFile)
    }

    override fun getAllTasks(): List<PigeonDownloadTask> {
        return controller?.getAllTasks() ?: emptyList()
    }

    override fun getTask(taskId: String): PigeonDownloadTask? {
        return controller?.getTask(taskId)
    }

    override fun clearHistory() {
        controller?.clearHistory()
    }

    override fun setConcurrencyLimit(limit: Long) {
        controller?.setConcurrencyLimit(limit.toInt())
    }
}
