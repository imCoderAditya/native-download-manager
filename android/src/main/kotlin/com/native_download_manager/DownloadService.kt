package com.native_download_manager

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class DownloadService : Service() {

    companion object {
        const val ACTION_START = "com.native_download_manager.ACTION_START"
        const val ACTION_STOP = "com.native_download_manager.ACTION_STOP"
        const val ACTION_PAUSE = "com.native_download_manager.ACTION_PAUSE"
        const val ACTION_RESUME = "com.native_download_manager.ACTION_RESUME"
        const val ACTION_CANCEL = "com.native_download_manager.ACTION_CANCEL"
        const val ACTION_RETRY = "com.native_download_manager.ACTION_RETRY"

        const val EXTRA_TASK_ID = "com.native_download_manager.EXTRA_TASK_ID"
        const val EXTRA_TASK_NAME = "com.native_download_manager.EXTRA_TASK_NAME"
        const val EXTRA_SPEED = "com.native_download_manager.EXTRA_SPEED"
        const val EXTRA_PROGRESS = "com.native_download_manager.EXTRA_PROGRESS"
        const val EXTRA_STATUS = "com.native_download_manager.EXTRA_STATUS"

        private const val CHANNEL_ID = "native_download_channel"
        private const val NOTIFICATION_ID = 101
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val taskId = intent?.getStringExtra(EXTRA_TASK_ID)

        when (action) {
            ACTION_START -> {
                val taskName = intent.getStringExtra(EXTRA_TASK_NAME) ?: "File"
                val speed = intent.getStringExtra(EXTRA_SPEED) ?: ""
                val progress = intent.getIntExtra(EXTRA_PROGRESS, 0)
                val status = intent.getIntExtra(EXTRA_STATUS, 1)

                val notification = createInteractiveNotification(taskId, taskName, speed, progress, status)
                startForeground(NOTIFICATION_ID, notification)
            }
            ACTION_PAUSE -> {
                if (taskId != null) {
                    DownloadManagerController.getInstance(applicationContext).pause(taskId)
                }
            }
            ACTION_RESUME -> {
                if (taskId != null) {
                    DownloadManagerController.getInstance(applicationContext).resume(taskId)
                }
            }
            ACTION_CANCEL -> {
                if (taskId != null) {
                    DownloadManagerController.getInstance(applicationContext).cancel(taskId)
                }
            }
            ACTION_RETRY -> {
                if (taskId != null) {
                    DownloadManagerController.getInstance(applicationContext).retry(taskId)
                }
            }
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createInteractiveNotification(
        taskId: String?,
        taskName: String,
        speed: String,
        progress: Int,
        status: Int
    ): Notification {
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val contentText = if (speed.isNotEmpty()) "$taskName • $speed" else "$taskName • $progress%"
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Downloading in background")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)

        if (progress in 1..99) {
            builder.setProgress(100, progress, false)
        } else {
            builder.setProgress(0, 0, true)
        }

        if (!taskId.isNullOrEmpty()) {
            if (status == 1) { // Downloading
                val pauseIntent = Intent(this, DownloadService::class.java).apply {
                    action = ACTION_PAUSE
                    putExtra(EXTRA_TASK_ID, taskId)
                }
                val pausePendingIntent = PendingIntent.getService(this, 1, pauseIntent, flag)
                builder.addAction(android.R.drawable.ic_media_pause, "Pause", pausePendingIntent)
            } else if (status == 2) { // Paused
                val resumeIntent = Intent(this, DownloadService::class.java).apply {
                    action = ACTION_RESUME
                    putExtra(EXTRA_TASK_ID, taskId)
                }
                val resumePendingIntent = PendingIntent.getService(this, 2, resumeIntent, flag)
                builder.addAction(android.R.drawable.ic_media_play, "Resume", resumePendingIntent)
            } else if (status == 4) { // Failed
                val retryIntent = Intent(this, DownloadService::class.java).apply {
                    action = ACTION_RETRY
                    putExtra(EXTRA_TASK_ID, taskId)
                }
                val retryPendingIntent = PendingIntent.getService(this, 4, retryIntent, flag)
                builder.addAction(android.R.drawable.stat_notify_sync, "Retry", retryPendingIntent)
            }

            // Cancel action button
            val cancelIntent = Intent(this, DownloadService::class.java).apply {
                action = ACTION_CANCEL
                putExtra(EXTRA_TASK_ID, taskId)
            }
            val cancelPendingIntent = PendingIntent.getService(this, 3, cancelIntent, flag)
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelPendingIntent)
        }

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Downloads"
            val descriptionText = "Service for native file downloading"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
