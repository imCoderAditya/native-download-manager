# native_download_manager

[![pub package](https://img.shields.io/pub/v/native_download_manager.svg?color=teal)](https://pub.dev/packages/native_download_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey.svg)](https://pub.dev/packages/native_download_manager)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-cyan.svg)](https://flutter.dev)

A production-ready, high-performance Flutter package providing robust, native background downloading for Android and iOS. 

It manages foreground services, custom notifications, in-page live progress cards, sleek download dialogs, priority-based queues, network/charging/battery constraints, integrity checks, and auto-resume capabilities across app restarts and device reboots.

---

## 🚀 Key Features

* **⚡ Native Background Downloading**: Keeps downloading files seamlessly even when the app is suspended, minimized, or terminated by the OS.
* **🖼️ In-Page Live Progress Widget**: Easily embed `AppDownloadService.currentDownloadWidget()` directly in any screen to show live download progress cards without popups.
* **💬 Download Progress Dialog**: Trigger downloads with an automatic progress modal using `AppDownloadService.downloadWithDialog(...)`.
* **📁 Public Downloads App Visibility**:
  * **Android**: Uses `MediaStore.Downloads` so completed files automatically appear at the top of the device's **"My Files" / "Downloads"** app.
  * **iOS**: Fully integrated with the Apple **Files** app (`On My iPhone` -> `[App Name]`).
* **🔄 Graceful Duplicate Handling**: Downloading with `overwrite: false` automatically resolves file name collisions (e.g., `document.pdf` -> `document(1).pdf` -> `document(2).pdf`) without throwing errors.
* **🔄 Auto-Resume Recovery**: Resumes active and pending downloads automatically on app restart and after device reboots (Android).
* **🚦 Concurrency & Priority Queue**: Configure concurrent download limits and assign priority levels (`low`, `normal`, `high`) to tasks.
* **🔋 Constraints Monitoring**: Limit downloads to WiFi-only, charging-only, or cellular-restricted conditions. Tasks automatically pause when constraints are violated and resume when satisfied.
* **📊 Accurate Real-Time Progress**: Streams instant progress metrics (percentage, bytes downloaded, total bytes, speed in B/s, KB/s, or MB/s, and ETA).
* **🔒 Integrity Verification**: Validate file checksums using MD5 or SHA-256 automatically upon completion.
* **🌐 HTTP Configuration**: Set custom HTTP headers, cookies, redirects, and authorization (Basic, Bearer, Signed URLs).
* **📄 Range Requests Support**: Resumes partially downloaded files from where they left off by sending HTTP Range requests.
* **🎨 100% Full UI Customization**: Customize card background colors, progress bar colors, typography, border radius, action button visibility, custom badges, and custom icons.

---

## 🛠️ Installation

Add `native_download_manager` to your `pubspec.yaml`:

```yaml
dependencies:
  native_download_manager: ^1.0.3
```

Import it in your Dart code:

```dart
import 'package:native_download_manager/native_download_manager.dart';
```

---

## ⚙️ Platform Setup

### 🤖 Android Setup

1. Add the permissions to your `android/app/src/main/AndroidManifest.xml`:

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

2. Register the service and boot receiver inside the `<application>` tag:

```xml
<service
    android:name="com.native_download_manager.DownloadService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="dataSync" />

<receiver
    android:name="com.native_download_manager.BootReceiver"
    android:enabled="true"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

### 🍏 iOS Setup

1. Ensure your deployment target is at least **iOS 13.0** in your `Podfile`:

```ruby
platform :ios, '13.0'
```

2. To make files visible in the iOS **Files** app (under "On My iPhone"), add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 📖 Quick Start

### 1. In-Page Download (No Popup Dialog)

Trigger a background download on button press, and render a live progress card directly on your screen:

```dart
// 1. Trigger background download on button press
ElevatedButton.icon(
  onPressed: () {
    AppDownloadService.startDownload(
      url: 'https://files.catbox.moe/vxirfe.pdf',
      fileName: 'vxirfe_document.pdf',
      overwrite: false, // Auto-renames to vxirfe_document(1).pdf if file exists
    );
  },
  icon: const Icon(Icons.download_rounded),
  label: const Text('Download Document'),
),

// 2. Place this widget anywhere on your screen UI
AppDownloadService.currentDownloadWidget()
```

---

### 2. Download with Progress Dialog Modal

Trigger a download that automatically opens a progress dialog modal:

```dart
AppDownloadService.downloadWithDialog(
  context: context,
  url: 'https://files.catbox.moe/vxirfe.pdf',
  fileName: 'document.pdf',
  dialogTitle: 'Downloading PDF Document...',
  overwrite: false,
  showRecent: false, // Set to true to show past download history as well
);
```

---

### 3. Open Standalone Downloads Manager Modal

Show a modal dialog listing active downloads and recent download history:

```dart
AppDownloadService.showDownloadsDialog(context);
```

---

### 4. Direct Engine API

For low-level control, use `NativeDownloadManager`:

```dart
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

---

## 🎨 Full UI Customization

Customize colors, typography, progress bar colors, borders, custom icons, and button visibility across all widgets:

```dart
AppDownloadService.currentDownloadWidget(
  // 🎨 Styling
  cardBackgroundColor: Colors.grey.shade900,
  borderRadius: BorderRadius.circular(16),
  progressBarColor: Colors.tealAccent,
  accentColor: Colors.teal,

  // 📝 Typography
  fileNameTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  progressTextStyle: const TextStyle(color: Colors.white70, fontSize: 11),
  speedTextStyle: const TextStyle(color: Colors.tealAccent, fontSize: 11),

  // 🔘 Control Button Visibility
  showPauseButton: true,
  showResumeButton: true,
  showRetryButton: true,
  showCancelButton: true,

  // ⚡ Custom Badge & Icon Builders
  badgeBuilder: (status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(status.name.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.teal)),
  ),
  iconBuilder: (fileName) => const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
)
```

---

## 💡 Advanced Features

### Custom Headers & Auth Bearer Tokens

Set custom network parameters for authenticated endpoints:

```dart
final task = await NativeDownloadManager.download(
  url: "https://api.example.com/download/file",
  fileName: "secure_doc.pdf",
  headers: {
    "Authorization": "Bearer YOUR_JWT_TOKEN",
    "Accept": "application/pdf",
  },
);
```

### Checksum Integrity Verification

Verify file integrity using MD5 or SHA-256 automatically upon completion:

```dart
final task = await NativeDownloadManager.download(
  url: "https://example.com/release.zip",
  fileName: "release.zip",
  checksum: "9a0a1a2b3c4d5e6f...",
  checksumAlgorithm: "sha256", // Or "md5"
);
```

### Concurrency & Queue Management

```dart
// Set active concurrent download limit
await NativeDownloadManager().setConcurrencyLimit(3);

// Get all tasks (enqueued, running, completed, etc.)
List<DownloadTask> allTasks = await NativeDownloadManager().downloads();

// Clear completed/failed download history
await NativeDownloadManager().clearHistory();
```

---

## 📱 Ready-to-Use UI Templates

`native_download_manager` includes 10 pure dynamic UI templates out of the box:

1. `DashboardTemplatePage` - Downloads Dashboard & Stats Hub
2. `PdfInvoiceTemplatePage` - Single & Multiple PDF Invoice Downloader
3. `MediaVideoTemplatePage` - Large Video & Media Downloader
4. `BatchDownloadTemplatePage` - Batch & Concurrency Queue Manager
5. `AuthHeaderTemplatePage` - Authenticated & Custom Header Downloader
6. `PriorityQueueTemplatePage` - Priority Queue Scheduler
7. `ConstraintsTemplatePage` - WiFi & Battery Constraint Manager
8. `ChecksumVerifierTemplatePage` - SHA-256 / MD5 Checksum Verifier
9. `StorageHistoryTemplatePage` - File Storage & History Manager
10. `NotificationCustomUiTemplatePage` - Native System Notification Action Showcase

---

## 🧪 Quality Assurance

* **`flutter analyze`**: `No issues found!` (0 warnings, 0 errors)
* **`flutter test`**: `All 9 unit tests passed!`

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
