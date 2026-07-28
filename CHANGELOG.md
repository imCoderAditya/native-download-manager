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
