package com.native.download.manager.native_download_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device reboot complete. Recovering download queue...")
            context?.let { ctx ->
                val controller = DownloadManagerController.getInstance(ctx)
                val dbHelper = DownloadDatabaseHelper(ctx)
                val tasks = dbHelper.getAllTasks()
                
                // Reschedule any task that was running or enqueued
                tasks.forEach { task ->
                    if (task.status == 0L || task.status == 1L) { // enqueued or downloading
                        val request = dbHelper.getFullRequest(task.id)
                        if (request != null) {
                            Log.d("BootReceiver", "Re-queuing active task: ${task.id}")
                            controller.enqueue(request)
                        }
                    }
                }
            }
        }
    }
}
