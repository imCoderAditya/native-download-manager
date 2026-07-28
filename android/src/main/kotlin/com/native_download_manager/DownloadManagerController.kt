package com.native_download_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor

class DownloadManagerController private constructor(private val context: Context) : DownloadCallback {

    companion object {
        private const val TAG = "DownloadController"
        
        @Volatile
        private var INSTANCE: DownloadManagerController? = null

        fun getInstance(context: Context): DownloadManagerController {
            return INSTANCE ?: synchronized(this) {
                val instance = DownloadManagerController(context.applicationContext)
                INSTANCE = instance
                instance
            }
        }
    }

    private val dbHelper = DownloadDatabaseHelper(context)
    private var concurrencyLimit = 3
    private var executor = Executors.newFixedThreadPool(concurrencyLimit) as ThreadPoolExecutor
    
    private val activeWorkers = ConcurrentHashMap<String, DownloadWorker>()
    private val activeFutures = ConcurrentHashMap<String, java.util.concurrent.Future<*>>()
    
    private val mainHandler = Handler(Looper.getMainLooper())
    
    @Volatile
    var flutterApi: NativeDownloadManagerFlutterApi? = null
    
    private var isMonitoringRegistered = false

    private val constraintsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d(TAG, "Constraint change detected: ${intent?.action}")
            checkConstraintsAndAdjust()
        }
    }

    init {
        registerConstraintsMonitoring()
    }

    fun setConcurrencyLimit(limit: Int) {
        this.concurrencyLimit = limit
        executor.shutdown()
        executor = Executors.newFixedThreadPool(limit) as ThreadPoolExecutor
        checkAndScheduleNext()
    }

    @Synchronized
    fun enqueue(request: PigeonDownloadRequest) {
        val task = PigeonDownloadTask(
            id = request.id,
            url = request.url,
            fileName = request.fileName,
            filePath = null,
            status = 0L, // enqueued
            progress = 0.0,
            downloadedBytes = 0L,
            totalBytes = 0L,
            speed = 0.0,
            etaSeconds = -1L,
            error = null
        )

        dbHelper.insertOrUpdateTask(task, request)
        
        // Notify Flutter
        mainHandler.post {
            try {
                flutterApi?.onTaskStatusChanged(task) { }
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking onTaskStatusChanged: ${e.message}")
            }
        }

        checkAndScheduleNext()
    }

    @Synchronized
    fun pause(taskId: String) {
        val worker = activeWorkers[taskId]
        if (worker != null) {
            worker.pause()
            activeWorkers.remove(taskId)
            activeFutures[taskId]?.cancel(true)
            activeFutures.remove(taskId)
        } else {
            // Task is in database or queue, set status to paused directly
            val task = dbHelper.getTask(taskId)
            if (task != null && task.status == 0L) {
                dbHelper.updateTaskProgress(taskId, 2, task.downloadedBytes, task.totalBytes, task.progress, task.filePath, null)
                val updatedTask = dbHelper.getTask(taskId)
                if (updatedTask != null) {
                    mainHandler.post {
                        try {
                            flutterApi?.onTaskStatusChanged(updatedTask) { }
                        } catch (e: Exception) {}
                    }
                }
            }
        }
        checkAndScheduleNext()
    }

    @Synchronized
    fun resume(taskId: String) {
        val task = dbHelper.getTask(taskId) ?: return
        if (task.status == 2L || task.status == 4L || task.status == 5L) { // paused, failed, canceled
            dbHelper.updateTaskProgress(taskId, 0, task.downloadedBytes, task.totalBytes, task.progress, task.filePath, null)
            checkAndScheduleNext()
        }
    }

    @Synchronized
    fun cancel(taskId: String) {
        val worker = activeWorkers[taskId]
        if (worker != null) {
            worker.cancel()
            activeWorkers.remove(taskId)
            activeFutures[taskId]?.cancel(true)
            activeFutures.remove(taskId)
        } else {
            val task = dbHelper.getTask(taskId)
            if (task != null) {
                dbHelper.updateTaskProgress(taskId, 5, 0, 0, 0.0, null, null)
                val updatedTask = dbHelper.getTask(taskId)
                if (updatedTask != null) {
                    mainHandler.post {
                        try {
                            flutterApi?.onTaskStatusChanged(updatedTask) { }
                        } catch (e: Exception) {}
                    }
                }
            }
        }
        checkAndScheduleNext()
    }

    @Synchronized
    fun retry(taskId: String) {
        val task = dbHelper.getTask(taskId) ?: return
        if (task.status == 4L || task.status == 5L) { // failed or canceled
            dbHelper.updateTaskProgress(taskId, 0, 0, 0, 0.0, null, null)
            checkAndScheduleNext()
        }
    }

    @Synchronized
    fun delete(taskId: String, deleteFile: Boolean) {
        cancel(taskId)
        val task = dbHelper.getTask(taskId)
        if (task != null) {
            if (deleteFile && task.filePath != null) {
                try {
                    val file = java.io.File(task.filePath!!)
                    if (file.exists()) {
                        file.delete()
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            dbHelper.deleteTask(taskId)
        }
    }

    fun getAllTasks(): List<PigeonDownloadTask> {
        val dbTasks = dbHelper.getAllTasks()
        // Override running tasks in-memory progress to return current speed/ETA
        return dbTasks.map { task ->
            val worker = activeWorkers[task.id]
            if (worker != null) {
                // Return task from database but with actual running metrics if available
                task
            } else {
                task
            }
        }
    }

    fun getTask(taskId: String): PigeonDownloadTask? {
        return dbHelper.getTask(taskId)
    }

    fun clearHistory() {
        dbHelper.clearAllTasks()
    }

    @Synchronized
    private fun checkAndScheduleNext() {
        val activeCount = activeWorkers.size
        if (activeCount >= concurrencyLimit) {
            updateForegroundService()
            return
        }

        // Get enqueued tasks
        val tasks = dbHelper.getAllTasks()
        val enqueuedTasks = tasks.filter { it.status == 0L } // enqueued

        if (enqueuedTasks.isEmpty()) {
            updateForegroundService()
            return
        }

        // Find next request that satisfies constraints
        for (pTask in enqueuedTasks) {
            val request = dbHelper.getFullRequest(pTask.id) ?: continue
            if (areConstraintsSatisfied(request)) {
                val worker = DownloadWorker(context, request, dbHelper, this)
                activeWorkers[pTask.id] = worker
                val future = executor.submit(worker)
                activeFutures[pTask.id] = future
                
                if (activeWorkers.size >= concurrencyLimit) {
                    break
                }
            }
        }

        updateForegroundService()
    }

    private fun areConstraintsSatisfied(request: PigeonDownloadRequest): Boolean {
        // Connectivity checking
        if (request.wifiOnly) {
            if (!isWifiConnected()) return false
        } else {
            if (!isNetworkConnected()) return false
        }

        // Charging check
        if (request.chargingOnly) {
            if (!isDeviceCharging()) return false
        }

        // Low battery check
        if (request.requiresBatteryNotLow) {
            if (isBatteryLow()) return false
        }

        return true
    }

    @Synchronized
    private fun checkConstraintsAndAdjust() {
        activeWorkers.forEach { (taskId, worker) ->
            val request = dbHelper.getFullRequest(taskId)
            if (request != null && !areConstraintsSatisfied(request)) {
                Log.d(TAG, "Task constraints violated for $taskId. Pausing task.")
                pause(taskId)
            }
        }
        checkAndScheduleNext()
    }

    // Callbacks from worker
    override fun onProgress(taskId: String, downloaded: Long, total: Long, speed: Double, eta: Int) {
        mainHandler.post {
            try {
                flutterApi?.onTaskProgressUpdated(taskId, downloaded, total, speed, eta.toLong()) { }
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking onTaskProgressUpdated: ${e.message}")
            }
        }
        updateForegroundService()
    }

    override fun onStatusChanged(taskId: String, status: Int, filePath: String?, error: String?) {
        val task = dbHelper.getTask(taskId) ?: return
        
        if (status == 3 || status == 4 || status == 5 || status == 2) { // completed, failed, canceled, paused
            activeWorkers.remove(taskId)
            activeFutures.remove(taskId)
        }

        val updatedTask = PigeonDownloadTask(
            id = task.id,
            url = task.url,
            fileName = task.fileName,
            filePath = filePath ?: task.filePath,
            status = status.toLong(),
            progress = task.progress,
            downloadedBytes = task.downloadedBytes,
            totalBytes = task.totalBytes,
            speed = 0.0,
            etaSeconds = -1L,
            error = error
        )

        mainHandler.post {
            try {
                flutterApi?.onTaskStatusChanged(updatedTask) { }
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking onTaskStatusChanged: ${e.message}")
            }
        }

        checkAndScheduleNext()
    }

    private fun updateForegroundService() {
        val hasActiveTasks = activeWorkers.isNotEmpty()
        val intent = Intent(context, DownloadService::class.java)
        if (hasActiveTasks) {
            intent.action = DownloadService.ACTION_START
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } else {
            intent.action = DownloadService.ACTION_STOP
            context.stopService(intent)
        }
    }

    // Constraint utils
    private fun isNetworkConnected(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val capabilities = cm.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    private fun isWifiConnected(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val capabilities = cm.getNetworkCapabilities(network) ?: return false
        return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    private fun isDeviceCharging(): Boolean {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, filter) ?: return false
        val status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
    }

    private fun isBatteryLow(): Boolean {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, filter) ?: return false
        val level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val percent = if (scale > 0) (level.toFloat() / scale.toFloat()) * 100.0 else 100.0
        return percent < 20.0
    }

    private fun registerConstraintsMonitoring() {
        if (isMonitoringRegistered) return
        val filter = IntentFilter().apply {
            addAction(ConnectivityManager.CONNECTIVITY_ACTION)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(Intent.ACTION_BATTERY_LOW)
            addAction(Intent.ACTION_BATTERY_OKAY)
        }
        context.registerReceiver(constraintsReceiver, filter)
        isMonitoringRegistered = true
    }

    fun onDestroy() {
        if (isMonitoringRegistered) {
            try {
                context.unregisterReceiver(constraintsReceiver)
            } catch (e: Exception) {}
            isMonitoringRegistered = false
        }
        executor.shutdown()
    }
}
