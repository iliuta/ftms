import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:ftms/features/fit_files/fit_file_manager_page.dart';
import 'package:ftms/core/services/fit/fit_file_manager.dart';
import 'package:ftms/core/services/strava/strava_service.dart';

// Generate mocks for the services
@GenerateMocks([FitFileManager, StravaService])
void main() {
  group('FitFileManagerPage', () {
    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FitFileManagerPage(),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show loading state during initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FitFileManagerPage(),
        ),
      );
      
      // Just test that the page loads without crashing
      // Wait a bit for initial load but don't wait for full settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show app bar with title and refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FitFileManagerPage(),
        ),
      );

      expect(find.text('FIT Files'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show refresh button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FitFileManagerPage(),
        ),
      );

      // Allow initial frame to render
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      // Test that refresh button can be tapped without waiting for async operations
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      
      // Should still show the refresh icon after tap
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('FitFileInfo', () {
    test('should format file size correctly', () {
      // Test bytes
      final smallFile = FitFileInfo(
        fileName: 'small.fit',
        filePath: '/path/small.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 512,
      );
      expect(smallFile.formattedSize, '512B');

      // Test kilobytes
      final mediumFile = FitFileInfo(
        fileName: 'medium.fit',
        filePath: '/path/medium.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 1536, // 1.5 KB
      );
      expect(mediumFile.formattedSize, '1.5KB');

      // Test megabytes
      final largeFile = FitFileInfo(
        fileName: 'large.fit',
        filePath: '/path/large.fit',
        creationDate: DateTime.now(),
        fileSizeBytes: 2097152, // 2 MB
      );
      expect(largeFile.formattedSize, '2.0MB');
    });

    test('should create FitFileInfo with all properties', () {
      final now = DateTime.now();
      final fitFile = FitFileInfo(
        fileName: 'test.fit',
        filePath: '/path/to/test.fit',
        creationDate: now,
        fileSizeBytes: 1024,
      );

      expect(fitFile.fileName, 'test.fit');
      expect(fitFile.filePath, '/path/to/test.fit');
      expect(fitFile.creationDate, now);
      expect(fitFile.fileSizeBytes, 1024);
      expect(fitFile.formattedSize, '1.0KB');
    });
  });
}
