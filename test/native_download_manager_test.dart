import 'package:flutter_test/flutter_test.dart';
import 'package:native_download_manager/native_download_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadStatus Enums', () {
    test('converts correctly from index', () {
      expect(DownloadStatus.fromInt(0), DownloadStatus.enqueued);
      expect(DownloadStatus.fromInt(1), DownloadStatus.downloading);
      expect(DownloadStatus.fromInt(2), DownloadStatus.paused);
      expect(DownloadStatus.fromInt(3), DownloadStatus.completed);
      expect(DownloadStatus.fromInt(4), DownloadStatus.failed);
      expect(DownloadStatus.fromInt(5), DownloadStatus.canceled);
      expect(DownloadStatus.fromInt(99), DownloadStatus.failed); // Default fallback
    });
  });

  group('DownloadPriority Enums', () {
    test('converts correctly from index', () {
      expect(DownloadPriority.fromInt(0), DownloadPriority.low);
      expect(DownloadPriority.fromInt(1), DownloadPriority.normal);
      expect(DownloadPriority.fromInt(2), DownloadPriority.high);
      expect(DownloadPriority.fromInt(-1), DownloadPriority.normal); // Default fallback
    });
  });

  group('DownloadProgress Calculations', () {
    test('percentage calculation is correct', () {
      const progress = DownloadProgress(
        taskId: '123',
        downloadedBytes: 50,
        totalBytes: 100,
        speed: 10.0,
        etaSeconds: 5,
      );
      expect(progress.percentage, 50.0);
    });

    test('percentage returns 0.0 when total is 0', () {
      const progress = DownloadProgress(
        taskId: '123',
        downloadedBytes: 0,
        totalBytes: 0,
        speed: 0.0,
        etaSeconds: -1,
      );
      expect(progress.percentage, 0.0);
    });

    test('formats speed correctly', () {
      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 512,
          etaSeconds: 1,
        ).formattedSpeed,
        '512.0 B/s',
      );

      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 2048,
          etaSeconds: 1,
        ).formattedSpeed,
        '2.0 KB/s',
      );

      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 1048576 * 1.5,
          etaSeconds: 1,
        ).formattedSpeed,
        '1.5 MB/s',
      );
    });

    test('formats ETA correctly', () {
      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 10,
          etaSeconds: 5,
        ).formattedEta,
        '5s',
      );

      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 10,
          etaSeconds: 65,
        ).formattedEta,
        '01:05',
      );

      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 10,
          totalBytes: 100,
          speed: 0,
          etaSeconds: -1,
        ).formattedEta,
        '--:--',
      );
    });

    test('formats size ratio correctly', () {
      expect(
        const DownloadProgress(
          taskId: '1',
          downloadedBytes: 1024 * 1024 * 5, // 5MB
          totalBytes: 1024 * 1024 * 10,    // 10MB
          speed: 10,
          etaSeconds: 1,
        ).formattedSizeRatio,
        '5.0 MB / 10.0 MB',
      );
    });
  });

  group('Pigeon Mapping', () {
    test('maps PigeonDownloadTask to user-facing DownloadTask correctly', () {
      final pigeonTask = PigeonDownloadTask(
        id: 'task_id_123',
        url: 'http://example.com',
        fileName: 'test.zip',
        filePath: '/path/to/test.zip',
        status: 3, // completed
        progress: 1.0,
        downloadedBytes: 1000,
        totalBytes: 1000,
        speed: 0.0,
        etaSeconds: -1,
        error: null,
      );

      final mappedTask = NativeDownloadManager.mapPigeonTask(pigeonTask);

      expect(mappedTask.id, 'task_id_123');
      expect(mappedTask.url, 'http://example.com');
      expect(mappedTask.fileName, 'test.zip');
      expect(mappedTask.filePath, '/path/to/test.zip');
      expect(mappedTask.status, DownloadStatus.completed);
      expect(mappedTask.progress.downloadedBytes, 1000);
      expect(mappedTask.progress.totalBytes, 1000);
      expect(mappedTask.progress.percentage, 100.0);
    });
  });

  group('DownloadTask Streams Lifecycle', () {
    test('statusStream and progressStream create valid streams', () async {
      final task = DownloadTask(
        id: 'test_task_1',
        url: 'http://example.com',
        fileName: 'file.pdf',
        status: DownloadStatus.enqueued,
        progress: const DownloadProgress(
          taskId: 'test_task_1',
          downloadedBytes: 0,
          totalBytes: 100,
          speed: 0,
          etaSeconds: -1,
        ),
      );

      expect(task.statusStream, isA<Stream<DownloadTask>>());
      expect(task.progressStream, isA<Stream<DownloadProgress>>());
    });
  });
}
