## 1.0.5

- Fixed iOS CocoaPods source files structure by moving native Swift files to `Classes/` directory for full pub.dev consumer compatibility.
- Fixed invalid Kotlin (`1.9.22`) and Android Gradle Plugin (`8.2.1`) build configurations in `android/build.gradle.kts`.
- Fixed real-time reactive UI progress updates across `CurrentDownloadWidget`, `RecentDownloadsDialogList`, `DashboardTemplatePage`, and `BatchDownloadTemplatePage`.
- Calibrated native progress emission frequency to 250ms interval on Android and iOS for smooth progress bar animations and accurate speed calculations.
- Added ProGuard consumer keep rules (`android/proguard-rules.pro`) for release build compatibility.
- Added Android 14 Foreground Service crash prevention guards.

## 1.0.4

- Added `AppDownloadService.currentDownloadWidget()` & `CurrentDownloadWidget` in-page live progress card component.
- Added `AppDownloadService.startDownload(...)` helper for triggering background downloads from button `onPressed` handlers without popup modals.
- Added 100% full UI customization options across all widgets (`cardBackgroundColor`, `borderRadius`, `progressBarColor`, `accentColor`, typography, custom `badgeBuilder`, `iconBuilder`, and control button visibility parameters).
- Added Android `MediaStore.Downloads` integration so completed files automatically appear at the top of the phone's **"My Files" / "Downloads"** app.
- Improved Android Scoped Storage compatibility on Android 10+ (API 29+).
- Enhanced `overwrite: false` duplicate file resolution to auto-increment file names (`file(1).ext`) seamlessly on Android and iOS.
- Updated 10 Ready-to-Use pure dynamic UI templates.
- Updated comprehensive API parameter tables and documentation in `README.md`.

## 1.0.3

- Fixed an issue where `DownloadTask.statusStream` remained open after a task reached a terminal state (`completed`, `failed`, `canceled`), causing `await for` loops in Dart to hang indefinitely.
- Fixed progress calculation and status synchronization for chunked downloads (`totalBytes == -1`).
- Enforced strict failure with `FileAlreadyExistsException` when `overwrite: false` and the destination file already exists.

## 1.0.2

- Fixed iOS Swift Package Manager (SPM) `FlutterFramework` dependency resolution.
- Updated iOS build settings and example application version metadata.

## 1.0.1

- Added default fallback to Android Public Downloads directory (`/storage/emulated/0/Download/`) so downloaded files immediately appear in the device File Manager, Gallery, and Downloads app.
- Added `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` permissions to AndroidManifest for full compatibility across older and newer Android versions.
- Fixed an issue on Android 11+ where files downloaded to app-private storage were hidden from the system File Manager due to Scoped Storage restrictions.

## 1.0.0

- Initial stable release.
- Added Android Foreground Service support for background downloads.
- Added iOS Background URLSession integration for background downloads.
- Support for pause, resume (via Range requests), retry, cancel, and task deletion.
- Real-time progress monitoring: download speed, ETA, percentage, bytes ratio.
- Concurrency queue management and priority queue support.
- Network and power constraints: wifiOnly, chargingOnly, low battery checking.
- Auto-resume after app restart and device boot completed (Android).
- Integrity checksum verification (MD5, SHA-256).
- Complete Material 3 example app.
