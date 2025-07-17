import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/fit/fit_file_manager.dart';

void main() {
  group('FIT File Management - Integration Test', () {
    test('FitFileInfo should format sizes correctly', () {
      final smallFile = FitFileInfo(
        fileName: 'small.fit',
        filePath: '/path/small.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 512,
      );
      expect(smallFile.formattedSize, '512B');

      final mediumFile = FitFileInfo(
        fileName: 'medium.fit',
        filePath: '/path/medium.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 1536, // 1.5 KB
      );
      expect(mediumFile.formattedSize, '1.5KB');

      final largeFile = FitFileInfo(
        fileName: 'large.fit',
        filePath: '/path/large.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 2097152, // 2 MB
      );
      expect(largeFile.formattedSize, '2.0MB');
    });

    test('FitFileManager should handle non-existent directories', () async {
      final manager = FitFileManager();
      final files = await manager.getAllFitFiles();
      // Should return empty list without throwing errors
      expect(files, isA<List<FitFileInfo>>());
    });

    test('FitFileManager should handle file count correctly', () async {
      final manager = FitFileManager();
      final count = await manager.getFitFileCount();
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('FitFileManager should handle total size correctly', () async {
      final manager = FitFileManager();
      final totalSize = await manager.getTotalFitFileSize();
      expect(totalSize, isA<int>());
      expect(totalSize, greaterThanOrEqualTo(0));
    });
  });
}
