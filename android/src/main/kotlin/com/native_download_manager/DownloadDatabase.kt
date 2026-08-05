package com.native_download_manager

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONObject

class DownloadDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "native_download_manager.db"
        private const val DATABASE_VERSION = 1
        const val TABLE_TASKS = "tasks"

        const val COLUMN_ID = "id"
        const val COLUMN_URL = "url"
        const val COLUMN_FILE_NAME = "file_name"
        const val COLUMN_FILE_PATH = "file_path"
        const val COLUMN_STATUS = "status"
        const val COLUMN_PROGRESS = "progress"
        const val COLUMN_DOWNLOADED_BYTES = "downloaded_bytes"
        const val COLUMN_TOTAL_BYTES = "total_bytes"
        const val COLUMN_PRIORITY = "priority"
        const val COLUMN_WIFI_ONLY = "wifi_only"
        const val COLUMN_CHARGING_ONLY = "charging_only"
        const val COLUMN_BATTERY_NOT_LOW = "battery_not_low"
        const val COLUMN_HEADERS = "headers"
        const val COLUMN_CHECKSUM = "checksum"
        const val COLUMN_CHECKSUM_ALGO = "checksum_algo"
        const val COLUMN_OVERWRITE = "overwrite"
        const val COLUMN_ERROR = "error"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = ("CREATE TABLE " + TABLE_TASKS + "("
                + COLUMN_ID + " TEXT PRIMARY KEY,"
                + COLUMN_URL + " TEXT,"
                + COLUMN_FILE_NAME + " TEXT,"
                + COLUMN_FILE_PATH + " TEXT,"
                + COLUMN_STATUS + " INTEGER,"
                + COLUMN_PROGRESS + " REAL,"
                + COLUMN_DOWNLOADED_BYTES + " INTEGER,"
                + COLUMN_TOTAL_BYTES + " INTEGER,"
                + COLUMN_PRIORITY + " INTEGER,"
                + COLUMN_WIFI_ONLY + " INTEGER,"
                + COLUMN_CHARGING_ONLY + " INTEGER,"
                + COLUMN_BATTERY_NOT_LOW + " INTEGER,"
                + COLUMN_HEADERS + " TEXT,"
                + COLUMN_CHECKSUM + " TEXT,"
                + COLUMN_CHECKSUM_ALGO + " TEXT,"
                + COLUMN_OVERWRITE + " INTEGER,"
                + COLUMN_ERROR + " TEXT" + ")")
        db.execSQL(createTable)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_TASKS")
        onCreate(db)
    }

    fun insertOrUpdateTask(task: PigeonDownloadTask, request: PigeonDownloadRequest?) {
        val db = this.writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_ID, task.id)
            put(COLUMN_URL, task.url)
            put(COLUMN_FILE_NAME, task.fileName)
            put(COLUMN_FILE_PATH, task.filePath)
            put(COLUMN_STATUS, task.status)
            put(COLUMN_PROGRESS, task.progress)
            put(COLUMN_DOWNLOADED_BYTES, task.downloadedBytes)
            put(COLUMN_TOTAL_BYTES, task.totalBytes)
            put(COLUMN_ERROR, task.error)

            if (request != null) {
                put(COLUMN_PRIORITY, request.priority)
                put(COLUMN_WIFI_ONLY, if (request.wifiOnly) 1 else 0)
                put(COLUMN_CHARGING_ONLY, if (request.chargingOnly) 1 else 0)
                put(COLUMN_BATTERY_NOT_LOW, if (request.requiresBatteryNotLow) 1 else 0)
                put(COLUMN_HEADERS, JSONObject(request.headers as Map<*, *>).toString())
                put(COLUMN_CHECKSUM, request.checksum)
                put(COLUMN_CHECKSUM_ALGO, request.checksumAlgorithm)
                put(COLUMN_OVERWRITE, if (request.overwrite) 1 else 0)
            }
        }
        db.insertWithOnConflict(TABLE_TASKS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun updateTaskProgress(taskId: String, status: Int, downloaded: Long, total: Long, progress: Double, filePath: String?, error: String?) {
        val db = this.writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_STATUS, status)
            put(COLUMN_DOWNLOADED_BYTES, downloaded)
            put(COLUMN_TOTAL_BYTES, total)
            put(COLUMN_PROGRESS, progress)
            if (filePath != null) {
                put(COLUMN_FILE_PATH, filePath)
                put(COLUMN_FILE_NAME, java.io.File(filePath).name)
            }
            if (error != null) {
                put(COLUMN_ERROR, error)
            }
        }
        db.update(TABLE_TASKS, values, "$COLUMN_ID = ?", arrayOf(taskId))
    }

    fun deleteTask(taskId: String) {
        val db = this.writableDatabase
        db.delete(TABLE_TASKS, "$COLUMN_ID = ?", arrayOf(taskId))
    }

    fun clearAllTasks() {
        val db = this.writableDatabase
        db.delete(TABLE_TASKS, null, null)
    }

    fun getAllTasks(): List<PigeonDownloadTask> {
        val list = mutableListOf<PigeonDownloadTask>()
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT * FROM $TABLE_TASKS", null)
        if (cursor.moveToFirst()) {
            do {
                val task = PigeonDownloadTask(
                    id = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ID)),
                    url = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_URL)),
                    fileName = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_NAME)),
                    filePath = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_PATH)),
                    status = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_STATUS)),
                    progress = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_PROGRESS)),
                    downloadedBytes = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_DOWNLOADED_BYTES)),
                    totalBytes = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_TOTAL_BYTES)),
                    speed = 0.0,
                    etaSeconds = -1L,
                    error = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ERROR))
                )
                list.add(task)
            } while (cursor.moveToNext())
        }
        cursor.close()
        return list
    }

    fun getTask(taskId: String): PigeonDownloadTask? {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT * FROM $TABLE_TASKS WHERE $COLUMN_ID = ?", arrayOf(taskId))
        var task: PigeonDownloadTask? = null
        if (cursor.moveToFirst()) {
            task = PigeonDownloadTask(
                id = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ID)),
                url = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_URL)),
                fileName = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_NAME)),
                filePath = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_PATH)),
                status = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_STATUS)),
                progress = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_PROGRESS)),
                downloadedBytes = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_DOWNLOADED_BYTES)),
                totalBytes = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_TOTAL_BYTES)),
                speed = 0.0,
                etaSeconds = -1L,
                error = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ERROR))
            )
        }
        cursor.close()
        return task
    }

    fun getFullRequest(taskId: String): PigeonDownloadRequest? {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT * FROM $TABLE_TASKS WHERE $COLUMN_ID = ?", arrayOf(taskId))
        var request: PigeonDownloadRequest? = null
        if (cursor.moveToFirst()) {
            val headersJson = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_HEADERS)) ?: "{}"
            val headersMap = mutableMapOf<String?, String?>()
            try {
                val json = JSONObject(headersJson)
                val keys = json.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    headersMap[key] = json.getString(key)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            request = PigeonDownloadRequest(
                id = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ID)),
                url = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_URL)),
                fileName = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_NAME)),
                destinationDirectory = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_FILE_PATH)),
                headers = headersMap,
                wifiOnly = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_WIFI_ONLY)) == 1,
                chargingOnly = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_CHARGING_ONLY)) == 1,
                requiresBatteryNotLow = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_BATTERY_NOT_LOW)) == 1,
                priority = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_PRIORITY)),
                checksum = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_CHECKSUM)),
                checksumAlgorithm = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_CHECKSUM_ALGO)),
                overwrite = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_OVERWRITE)) == 1
            )
        }
        cursor.close()
        return request
    }
}
