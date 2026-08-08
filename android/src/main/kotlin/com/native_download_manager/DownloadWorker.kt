package com.native_download_manager

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.Locale

interface DownloadCallback {
    fun onProgress(taskId: String, downloaded: Long, total: Long, speed: Double, eta: Int)
    fun onStatusChanged(taskId: String, status: Int, filePath: String?, error: String?)
}

class DownloadWorker(
    private val context: Context,
    private val request: PigeonDownloadRequest,
    private val dbHelper: DownloadDatabaseHelper,
    private val callback: DownloadCallback
) : Runnable {

    @Volatile
    private var isPaused = false

    @Volatile
    private var isCanceled = false

    fun pause() {
        isPaused = true
    }

    fun cancel() {
        isCanceled = true
    }

    override fun run() {
        var connection: HttpURLConnection? = null
        var inputStream: InputStream? = null
        var outputStream: RandomAccessFile? = null
        var file: File? = null

        callback.onStatusChanged(request.id, 1, null, null) // downloading
        dbHelper.updateTaskProgress(request.id, 1, 0, 0, 0.0, null, null)

        try {
            // Determine storage directory safely
            var destDir: File? = null
            if (!request.destinationDirectory.isNullOrEmpty()) {
                destDir = File(request.destinationDirectory)
            }
            if (destDir == null || (!destDir.exists() && !destDir.mkdirs())) {
                destDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                    ?: context.filesDir
            }

            if (!destDir.exists()) {
                destDir.mkdirs()
            }

            var targetFile = File(destDir, request.fileName)
            val isResuming = isPaused || dbHelper.getTask(request.id)?.status == 2L
            
            // Check overwrite policy
            if (targetFile.exists() && !request.overwrite && !isResuming) {
                val nameWithoutExt = targetFile.nameWithoutExtension
                val ext = targetFile.extension
                var counter = 1
                while (targetFile.exists()) {
                    val newName = if (ext.isNotEmpty()) "$nameWithoutExt($counter).$ext" else "$nameWithoutExt($counter)"
                    targetFile = File(destDir, newName)
                    counter++
                }
            }
            file = targetFile

            var downloadedBytes = 0L
            if (file.exists() && isResuming) {
                downloadedBytes = file.length()
            } else if (file.exists() && request.overwrite) {
                // If we aren't resuming a pause task and overwrite is true, delete existing file
                file.delete()
            }

            var currentUrl = request.url
            var redirectCount = 0
            val maxRedirects = 5

            while (true) {
                val urlObj = URL(currentUrl)
                connection = urlObj.openConnection() as HttpURLConnection
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.instanceFollowRedirects = false // we follow manually

                // Request headers
                val hasUserAgent = request.headers.keys.any { it?.equals("User-Agent", ignoreCase = true) == true }
                if (!hasUserAgent) {
                    connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
                }
                request.headers.forEach { (key, value) ->
                    if (key != null && value != null) {
                        connection.setRequestProperty(key, value)
                    }
                }

                // Range header if resuming
                if (downloadedBytes > 0) {
                    connection.setRequestProperty("Range", "bytes=$downloadedBytes-")
                }

                val responseCode = connection.responseCode

                if (responseCode == HttpURLConnection.HTTP_MOVED_TEMP ||
                    responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
                    responseCode == HttpURLConnection.HTTP_SEE_OTHER ||
                    responseCode == 307 || responseCode == 308
                ) {
                    redirectCount++
                    if (redirectCount > maxRedirects) {
                        throw Exception("Too many HTTP redirects")
                    }
                    val newUrl = connection.getHeaderField("Location")
                    currentUrl = URL(urlObj, newUrl).toString()
                    connection.disconnect()
                    continue
                }
                break
            }

            val responseCode = connection.responseCode
            val isPartialContent = responseCode == HttpURLConnection.HTTP_PARTIAL

            if (responseCode != HttpURLConnection.HTTP_OK && !isPartialContent) {
                throw Exception("Server returned HTTP response code: $responseCode")
            }

            val contentLength = connection.contentLength.toLong()
            var totalBytes = contentLength
            if (isPartialContent && contentLength > 0) {
                totalBytes = contentLength + downloadedBytes
            } else if (!isPartialContent) {
                downloadedBytes = 0L // reset since server didn't support partial content/range
            }

            // Disk space validation
            if (totalBytes > 0) {
                val freeSpace = destDir.usableSpace
                if (freeSpace < (totalBytes - downloadedBytes)) {
                    throw Exception("Insufficient storage space. Required: ${totalBytes - downloadedBytes} bytes, Free: $freeSpace bytes")
                }
            }

            inputStream = connection.inputStream
            outputStream = RandomAccessFile(file, "rw")
            if (isPartialContent) {
                outputStream.seek(downloadedBytes)
            } else {
                outputStream.setLength(0) // clear existing content
            }

            val buffer = ByteArray(4096)
            var bytesRead: Int
            var lastUpdateTimestamp = System.currentTimeMillis()
            var bytesDownloadedSinceLastUpdate = 0L
            var speed = 0.0

            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                if (isPaused) {
                    // Save pause status and exit
                    callback.onStatusChanged(request.id, 2, file.absolutePath, null) // paused
                    val pauseProgress = if (totalBytes > 0) (downloadedBytes.toDouble() / totalBytes) else 0.0
                    dbHelper.updateTaskProgress(request.id, 2, downloadedBytes, totalBytes, pauseProgress, file.absolutePath, null)
                    return
                }

                if (isCanceled) {
                    file.delete()
                    callback.onStatusChanged(request.id, 5, null, null) // canceled
                    dbHelper.updateTaskProgress(request.id, 5, 0, 0, 0.0, null, null)
                    return
                }

                outputStream.write(buffer, 0, bytesRead)
                downloadedBytes += bytesRead
                bytesDownloadedSinceLastUpdate += bytesRead

                val currentTime = System.currentTimeMillis()
                val timeDiff = currentTime - lastUpdateTimestamp

                if (timeDiff >= 250) {
                    speed = (bytesDownloadedSinceLastUpdate.toDouble() / (timeDiff.toDouble() / 1000.0))
                    val progress = if (totalBytes > 0) downloadedBytes.toDouble() / totalBytes.toDouble() else 0.0
                    val remainingBytes = if (totalBytes > 0) totalBytes - downloadedBytes else 0L
                    val eta = if (totalBytes > 0 && speed > 0) (remainingBytes / speed).toInt() else -1

                    callback.onProgress(request.id, downloadedBytes, totalBytes, speed, eta)
                    dbHelper.updateTaskProgress(request.id, 1, downloadedBytes, totalBytes, progress, file.absolutePath, null)

                    lastUpdateTimestamp = currentTime
                    bytesDownloadedSinceLastUpdate = 0
                }
            }

            // Completed downloading
            outputStream.close()
            outputStream = null

            val finalTotalBytes = if (totalBytes > 0) totalBytes else downloadedBytes

            // Validate Checksum if required
            if (request.checksum != null && request.checksumAlgorithm != null) {
                callback.onStatusChanged(request.id, 1, file.absolutePath, "Verifying checksum...")
                val verified = verifyChecksum(file, request.checksum!!, request.checksumAlgorithm!!)
                if (!verified) {
                    throw Exception("File integrity verification failed. Checksum mismatch.")
                }
            }

            // Register in MediaStore/system scans if public directory
            scanFile(context, file)

            // Flush final 100% progress update and database update BEFORE triggering completed status callback
            callback.onProgress(request.id, finalTotalBytes, finalTotalBytes, 0.0, 0)
            dbHelper.updateTaskProgress(request.id, 3, finalTotalBytes, finalTotalBytes, 1.0, file.absolutePath, null)
            callback.onStatusChanged(request.id, 3, file.absolutePath, null) // completed

        } catch (e: Exception) {
            e.printStackTrace()
            val errorMessage = e.message ?: "Unknown download error"
            callback.onStatusChanged(request.id, 4, null, errorMessage) // failed
            dbHelper.updateTaskProgress(request.id, 4, 0, 0, 0.0, null, errorMessage)
        } finally {
            try {
                inputStream?.close()
            } catch (e: Exception) {}
            try {
                outputStream?.close()
            } catch (e: Exception) {}
            connection?.disconnect()
        }
    }

    private fun verifyChecksum(file: File, expected: String, algorithm: String): Boolean {
        return try {
            val digest = MessageDigest.getInstance(algorithm.uppercase(Locale.US))
            val buffer = ByteArray(8192)
            val fis = file.inputStream()
            var read: Int
            while (fis.read(buffer).also { read = it } != -1) {
                digest.update(buffer, 0, read)
            }
            fis.close()
            val hashBytes = digest.digest()
            val sb = StringBuilder()
            for (b in hashBytes) {
                sb.append(String.format("%02x", b))
            }
            val actualChecksum = sb.toString()
            actualChecksum.equals(expected, ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }

    private fun scanFile(context: Context, file: File) {
        try {
            MediaScannerConnection.scanFile(
                context,
                arrayOf(file.absolutePath),
                null
            ) { _, _ -> }

            // Copy/Insert into Public Downloads folder so it shows up in My Files app
            copyToPublicDownloads(context, file, file.name)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun copyToPublicDownloads(context: Context, sourceFile: File, fileName: String) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = context.contentResolver
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, getMimeType(fileName))
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { out ->
                        sourceFile.inputStream().use { input ->
                            input.copyTo(out)
                        }
                    }
                }
            } else {
                val publicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                if (!publicDir.exists()) publicDir.mkdirs()
                val destFile = File(publicDir, fileName)
                sourceFile.copyTo(destFile, overwrite = true)
                MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), null, null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "")
        return if (extension.isNotEmpty()) {
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase(Locale.US))
                ?: "application/octet-stream"
        } else {
            "application/octet-stream"
        }
    }
}
