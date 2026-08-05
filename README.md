# native_download_manager

[![pub package](https://img.shields.io/pub/v/native_download_manager.svg?color=teal)](https://pub.dev/packages/native_download_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey.svg)](https://pub.dev/packages/native_download_manager)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-cyan.svg)](https://flutter.dev)

A production-ready, high-performance Flutter package for **Native Background Downloading** on Android and iOS. Built with native background services, real-time progress streams, live dialogs, in-page progress widgets, automatic duplicate file renaming, MediaStore/Files app visibility, and full UI customization.

---

## ✨ Key Features

* **⚡ Native Background Downloads**: Continues downloading seamlessly even when the app is suspended, minimized, or terminated.
* **🖼️ In-Page Live Progress Widget**: Easily embed `AppDownloadService.currentDownloadWidget()` directly in any screen to show live download progress cards without popups.
* **💬 Download Progress Dialog**: Trigger downloads with an automatic progress modal using `AppDownloadService.downloadWithDialog(...)`.
* **📁 Public Downloads App Visibility**:
  * **Android**: Uses `MediaStore.Downloads` so completed files automatically appear at the top of the device's **"My Files" / "Downloads"** app.
  * **iOS**: Fully integrated with the Apple **Files** app (`On My iPhone` -> `[App Name]`).
* **🔄 Graceful Duplicate Handling**: Downloading with `overwrite: false` automatically resolves file name collisions (e.g. `file.pdf` -> `file(1).pdf` -> `file(2).pdf`) without throwing errors.
* **🎨 100% Full UI Customization**: Customize card background colors, progress bar colors, typography, border radius, action button visibility, custom badges, and custom icons.
* **🔄 Auto-Resume & Reconnection**: Automatically resumes active downloads on app restarts and device reboots (Android).
* **🚦 Priority Queues & Concurrency**: Assign task priorities (`low`, `normal`, `high`) and set global concurrency limits.
* **🔋 Battery & Network Constraints**: Restrict downloads to WiFi-only or charging-only conditions.
* **🔒 Integrity Checksum**: Verify file hash integrity using MD5 or SHA-256 upon completion.
* **🔐 Custom Headers & Auth Tokens**: Supports Bearer tokens, custom headers, cookies, and signed URLs.

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

Add permissions to your `android/app/src/main/AndroidManifest.xml`:

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

Inside `<application>`, register the native background service:

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

Set minimum deployment target to **iOS 13.0** in your `Podfile`.

To make downloaded files visible in the iOS **Files** app (under `On My iPhone`), add these keys to `ios/Runner/Info.plist`:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 🚀 Usage Guide

### 1. In-Page Download (No Popup Dialog)

Trigger a background download from any button click, and render a live progress card directly on your screen:

```dart
// 1. Trigger background download on button press
ElevatedButton.icon(
  onPressed: () {
    AppDownloadService.startDownload(
      url: 'https://files.catbox.moe/vxirfe.pdf',
      fileName: 'vxirfe_document.pdf',
      overwrite: false, // Auto-renames to vxirfe_document(1).pdf if exists
    );
  },
  icon: const Icon(Icons.download_rounded),
  label: const Text('Download Invoice'),
),

// 2. Place this widget anywhere on your screen UI
AppDownloadService.currentDownloadWidget()
```

---

### 2. Download with Progress Dialog

Trigger a download that automatically opens a sleek progress dialog modal:

```dart
AppDownloadService.downloadWithDialog(
  context: context,
  url: 'https://files.catbox.moe/vxirfe.pdf',
  fileName: 'document.pdf',
  dialogTitle: 'Downloading PDF Document...',
  overwrite: false,
  showRecent: false, // Set to true to display recent download history as well
);
```

---

### 3. Open Standalone Downloads Manager Modal

Show a modal dialog listing active downloads and recent download history:

```dart
AppDownloadService.showDownloadsDialog(context);
```

---

### 4. Advanced Customization

You can fully customize colors, typography, progress bar colors, borders, custom icons, and button visibility across all widgets:

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

### 5. Raw Manager API

For advanced users needing direct access to stream controls and queue management:

```dart
// Start a download task
final task = await NativeDownloadManager.download(
  url: 'https://example.com/file.zip',
  fileName: 'file.zip',
  priority: DownloadPriority.high,
  headers: {'Authorization': 'Bearer YOUR_TOKEN'},
);

// Control active task
await task.pause();
await task.resume();
await task.cancel();
await task.retry();
await task.delete(deleteFile: true);

// Listen to progress streams
task.progressStream.listen((progress) {
  print('Percentage: ${progress.percentage}%');
  print('Speed: ${progress.formattedSpeed}');
  print('Size: ${progress.formattedSizeRatio}');
});
```

---

## 🎨 Included Ready-to-Use UI Templates

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

## 🧪 Verification & Quality Assurance

* **`flutter analyze`**: `No issues found!` (0 warnings, 0 errors)
* **`flutter test`**: `All 9 unit tests passed!`

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
