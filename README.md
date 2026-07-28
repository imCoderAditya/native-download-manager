# native_download_manager

[![pub package](https://img.shields.io/pub/v/native_download_manager.svg?color=teal)](https://pub.dev/packages/native_download_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey.svg)](https://pub.dev/packages/native_download_manager)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-cyan.svg)](https://flutter.dev)

A production-ready Flutter package providing high-performance, robust, and native background downloading for Android and iOS. It manages foreground services, custom notifications, priority-based queues, network/charging/battery constraints, integrity checks, and auto-resume capabilities across app restarts and device reboots.

---

## 🚀 Key Features

* **⚡ Background Downloading**: Keeps downloading files even when the app is suspended, minimized, or terminated by the OS.
* **🔄 Auto-Resume Recovery**: Resumes active and pending downloads automatically on app restart and after device reboots (Android).
* **🚦 Concurrency & Priority Queue**: Configure concurrent download limits and assign priority levels (`low`, `normal`, `high`) to tasks.
* **🔋 Constraints Monitoring**: Limit downloads to WiFi-only, charging-only, or cellular-restricted conditions. Tasks automatically pause when constraints are violated and resume when they are satisfied.
* **📊 Accurate Real-Time Progress**: Streams instant progress metrics (percentage, bytes downloaded, total bytes, speed in B/s, KB/s, or MB/s, and ETA).
* **🔒 Integrity Verification**: Validate file checksums using MD5 or SHA-256 automatically upon completion.
* **🌐 HTTP Configuration**: Set custom HTTP headers, cookies, redirects, and authorization (Basic, Bearer, Signed URLs).
* **📄 Range Requests Support**: Resumes partially downloaded files from where they left off by sending HTTP Range requests.
* **📂 Files App Integration (iOS)**: Easily configure downloads to save directly inside the Documents directory to make them visible in the Apple Files app.
* **📱 MediaStore Scanner (Android)**: Automatically scans completed files to register them in the Android system database, making them visible in default file managers.

---

## 🛠️ Installation

Add `native_download_manager` to your `pubspec.yaml`:

```yaml
dependencies:
  native_download_manager: ^1.0.1
```

---

## ⚙️ Platform Setup

### 🤖 Android Setup

1. Add the following permissions to your `AndroidManifest.xml` (the package handles them under the hood, but it's best practice to list them):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

2. Register the service and boot receiver inside the `<application>` tag (they are merged automatically from the package, but make sure your Gradle configuration has `minSdkVersion >= 21`):

```xml
<service
    android:name="com.native.download.manager.native_download_manager.DownloadService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="dataSync" />

<receiver
    android:name="com.native.download.manager.native_download_manager.BootReceiver"
    android:enabled="true"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

### 🍏 iOS Setup

Ensure your deployment target is at least **iOS 13.0** in your Podfile:

```ruby
platform :ios, '13.0'
```

To make files visible in the iOS **Files** app (under "On My iPhone"), add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 📖 Quick Start

### Start a Download Task

```dart
import 'package:native_download_manager/native_download_manager.dart';

// Start downloading a file
final task = await NativeDownloadManager.download(
  url: "https://example.com/movie.mp4",
  fileName: "movie.mp4",
  priority: DownloadPriority.high,
  networkConstraints: [NetworkConstraint.wifiOnly],
);

// Listen to progress updates
task.progressStream.listen((progress) {
  print("Progress: ${progress.percentage.toStringAsFixed(1)}%");
  print("Speed: ${progress.formattedSpeed}");
  print("ETA: ${progress.formattedEta}");
});

// Listen to status changes
task.statusStream.listen((updatedTask) {
  if (updatedTask.status == DownloadStatus.completed) {
    print("Download completed! Saved to: ${updatedTask.filePath}");
  } else if (updatedTask.status == DownloadStatus.failed) {
    print("Download failed: ${updatedTask.error}");
  }
});
```

### Control Active Downloads

```dart
// Pause the download
await task.pause();

// Resume the download (uses HTTP Range request if supported by host)
await task.resume();

// Cancel and delete temporary data
await task.cancel();

// Retry a failed task
await task.retry();

// Remove from database and optionally delete local file
await task.delete(deleteFile: true);
```

### Queue Management & Streams

You can monitor all downloads or set global constraints:

```dart
// Get all tasks (enqueued, running, completed, etc.)
List<DownloadTask> allTasks = await NativeDownloadManager().downloads();

// Set active concurrent download limit
await NativeDownloadManager().setConcurrencyLimit(3);

// Clear completed/failed download history
await NativeDownloadManager().clearHistory();

// Listen to progress updates globally across all tasks
NativeDownloadManager().progressStream.listen((progress) {
  print("Task ${progress.taskId} is downloading at ${progress.formattedSpeed}");
});
```

---

## 💡 Advanced Usage

### Custom Headers & Cookie Support

Set customized network options, e.g., for basic/bearer token authentication or session tracking:

```dart
final task = await NativeDownloadManager.download(
  url: "https://api.example.com/download/file",
  fileName: "secure_doc.pdf",
  headers: {
    "Authorization": "Bearer YOUR_JWT_TOKEN",
    "Accept": "application/pdf",
  },
  cookies: {
    "session_id": "xyz123abc",
  },
);
```

### Checksum Verification

Verify file integrity using MD5 or SHA-256 automatically upon completion:

```dart
final task = await NativeDownloadManager.download(
  url: "https://example.com/release.zip",
  fileName: "release.zip",
  checksum: "9a0a1a2b3c4d5e6f...",
  checksumAlgorithm: "sha256", // Or "md5"
);
```

---

## 📊 API Details

### `DownloadStatus`
| Enum Value | Description |
|---|---|
| `enqueued` | Task is added to queue and waiting for conditions. |
| `downloading` | Task is actively downloading. |
| `paused` | Task is paused and can be resumed. |
| `completed` | Task finished successfully. |
| `failed` | Task failed due to network, storage, or constraint issues. |
| `canceled` | Task was canceled by the user. |

### `DownloadPriority`
| Enum Value | Description |
|---|---|
| `low` | Lower scheduling priority. |
| `normal` | Default scheduling priority. |
| `high` | High scheduling priority; starts before others. |

### `NetworkConstraint`
* `wifiOnly`: Download only when connected to a Wi-Fi network.
* `chargingOnly`: Download only when the device is plugged in.
* `cellularRestricted`: Download only on unmetered networks (cellular restricted).

---

## ❓ FAQ

#### How is duplicate naming handled?
By default, files with duplicate names are renamed using a standard suffix counter format (e.g., `file(1).ext`, `file(2).ext`) if `overwrite: false` is passed. If `overwrite: true` is passed, the manager will overwrite/replace any existing file of the same name.

#### Does it support range requests?
Yes. If the server returns appropriate headers (`Accept-Ranges: bytes` or `Content-Range`), the package requests only the remaining bytes when resuming a paused task.

#### Does this work in background modes?
Yes. On Android, a Foreground Service runs to protect the download process from OS termination. On iOS, the system background `URLSession` configuration executes downloads at OS level, ensuring tasks progress even if the app is closed.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
