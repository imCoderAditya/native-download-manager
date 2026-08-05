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

1. Add permissions to `android/app/src/main/AndroidManifest.xml`:

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

2. To make files visible in the iOS **Files** app (under "On My iPhone"), add the following keys to `ios/Runner/Info.plist`:

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

## 📚 Complete API Reference & Parameters

### 1. `AppDownloadService.downloadWithDialog(...)`

Displays a download progress modal dialog with optional recent download history.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `context` | `BuildContext` | **Required** | The current build context. |
| `url` | `String` | **Required** | The remote file URL to download. |
| `fileName` | `String` | **Required** | Destination file name (e.g. `document.pdf`). |
| `destinationDirectory` | `String?` | `null` | Custom directory path. If null, uses app downloads directory. |
| `headers` | `Map<String, String>` | `{}` | Custom HTTP headers (e.g. Bearer auth token). |
| `priority` | `DownloadPriority` | `DownloadPriority.high` | Priority level (`low`, `normal`, `high`). |
| `overwrite` | `bool` | `true` | If false, auto-increments filename (`file(1).ext`) if file exists. |
| `dialogTitle` | `String` | `'Downloading File...'` | Header title of the dialog. |
| `showRecent` | `bool` | `false` | If true, displays past download history below active download. |
| `dialogShape` | `ShapeBorder?` | `null` | Custom shape border for the dialog. |
| `dialogBackgroundColor` | `Color?` | `null` | Custom background color for the dialog. |
| `dialogTitleTextStyle` | `TextStyle?` | `null` | Custom text style for dialog title. |
| `closeButtonText` | `String` | `'Close'` | Text for the close button. |
| `closeButton` | `Widget?` | `null` | Custom close button widget. |
| `cardBackgroundColor` | `Color?` | `null` | Card background color inside dialog. |
| `borderRadius` | `BorderRadiusGeometry?` | `null` | Custom border radius for cards. |
| `progressBarColor` | `Color?` | `null` | Progress bar fill color. |
| `accentColor` | `Color?` | `null` | Accent color for icons and highlights. |
| `fileNameTextStyle` | `TextStyle?` | `null` | Custom style for file name text. |
| `progressTextStyle` | `TextStyle?` | `null` | Custom style for percentage and size ratio text. |
| `speedTextStyle` | `TextStyle?` | `null` | Custom style for live speed text. |
| `badgeBuilder` | `Widget Function(DownloadStatus)?` | `null` | Custom status badge builder. |
| `iconBuilder` | `Widget Function(String)?` | `null` | Custom file icon builder. |

---

### 2. `AppDownloadService.startDownload(...)` & `downloadFile(...)`

Triggers background download without popping up a dialog modal.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `url` | `String` | **Required** | Remote URL to download. |
| `fileName` | `String` | **Required** | Target file name. |
| `destinationDirectory` | `String?` | `null` | Custom output directory path. |
| `headers` | `Map<String, String>` | `{}` | Custom HTTP request headers. |
| `priority` | `DownloadPriority` | `DownloadPriority.high` | Priority (`low`, `normal`, `high`). |
| `overwrite` | `bool` | `true` | Auto-renames if false. |
| `onProgress` | `Function(DownloadProgress)?` | `null` | Live progress callback. |
| `onStatusChanged` | `Function(DownloadTask)?` | `null` | Task status change callback. |
| `onSuccess` | `Function(String filePath)?` | `null` | Download completion callback. |
| `onError` | `Function(String error)?` | `null` | Download failure callback. |

---

### 3. `AppDownloadService.currentDownloadWidget(...)` / `CurrentDownloadWidget(...)`

In-page widget that renders ONLY the active downloading task on screen.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `taskId` | `String?` | `null` | Specific task ID to monitor. If null, monitors any active task. |
| `fileName` | `String?` | `null` | Specific file name to monitor. |
| `margin` | `EdgeInsetsGeometry?` | `null` | External card margin. |
| `padding` | `EdgeInsetsGeometry?` | `null` | Internal card padding. |
| `onCompleted` | `VoidCallback?` | `null` | Callback when download completes. |
| `onCancelled` | `VoidCallback?` | `null` | Callback when download is cancelled. |
| `cardBackgroundColor` | `Color?` | `null` | Card background color. |
| `borderRadius` | `BorderRadiusGeometry?` | `null` | Border radius. |
| `progressBarColor` | `Color?` | `null` | Progress bar fill color. |
| `accentColor` | `Color?` | `null` | Icon accent color. |
| `showPauseButton` | `bool` | `true` | Show/hide pause button. |
| `showResumeButton` | `bool` | `true` | Show/hide resume button. |
| `showRetryButton` | `bool` | `true` | Show/hide retry button. |
| `showCancelButton` | `bool` | `true` | Show/hide cancel button. |

---

### 4. `NativeDownloadManager.download(...)` (Raw Engine API)

Low-level download trigger method.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `url` | `String` | **Required** | Remote resource URL. |
| `fileName` | `String` | **Required** | Output file name. |
| `destinationDirectory` | `String?` | `null` | Custom directory. |
| `headers` | `Map<String, String>` | `{}` | HTTP headers. |
| `cookies` | `Map<String, String>` | `{}` | HTTP cookies. |
| `priority` | `DownloadPriority` | `DownloadPriority.normal` | Priority (`low`, `normal`, `high`). |
| `networkConstraints` | `List<NetworkConstraint>` | `[]` | Constraints (`wifiOnly`, `chargingOnly`). |
| `overwrite` | `bool` | `true` | Overwrite policy. |
| `checksum` | `String?` | `null` | Hash string for validation. |
| `checksumAlgorithm` | `String?` | `null` | Hash algorithm (`md5`, `sha256`). |

---

## 🎨 Full UI Customization Example

```dart
AppDownloadService.currentDownloadWidget(
  // 🎨 Custom Styling
  cardBackgroundColor: Colors.grey.shade900,
  borderRadius: BorderRadius.circular(16),
  progressBarColor: Colors.tealAccent,
  accentColor: Colors.teal,

  // 📝 Typography
  fileNameTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  progressTextStyle: const TextStyle(color: Colors.white70, fontSize: 11),
  speedTextStyle: const TextStyle(color: Colors.tealAccent, fontSize: 11),

  // 🔘 Action Controls
  showPauseButton: true,
  showResumeButton: true,
  showRetryButton: true,
  showCancelButton: true,

  // ⚡ Custom Builders
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

```dart
final task = await NativeDownloadManager.download(
  url: "https://example.com/release.zip",
  fileName: "release.zip",
  checksum: "9a0a1a2b3c4d5e6f...",
  checksumAlgorithm: "sha256", // Or "md5"
);
```

### Concurrency & Queue Control

```dart
// Set active concurrent download limit
await NativeDownloadManager().setConcurrencyLimit(3);

// Get all tasks
List<DownloadTask> allTasks = await NativeDownloadManager().downloads();

// Clear history
await NativeDownloadManager().clearHistory();
```

---

## 📱 Ready-to-Use UI Templates

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
