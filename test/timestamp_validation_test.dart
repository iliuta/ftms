import 'package:flutter_test/flutter_test.dart';
import 'package:fit_tool/fit_tool.dart';

void main() {
  group('Timestamp Validation Tests', () {
    test('toSecondsSince1989Epoch function should work correctly', () {
      // Test current timestamp conversion
      final now = DateTime.now();
      final fitTimestamp = toSecondsSince1989Epoch(now.millisecondsSinceEpoch);
      
      // FIT epoch is December 31, 1989 00:00:00 UTC
      final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
      final expectedSeconds = now.difference(fitEpoch).inSeconds;
      
      expect(fitTimestamp, equals(expectedSeconds));
      
      // Verify it's not a Unix timestamp (should be much larger)
      final unixTimestamp = now.millisecondsSinceEpoch ~/ 1000;
      expect(fitTimestamp, isNot(equals(unixTimestamp)));
      
      // FIT timestamp should be larger than Unix timestamp (more seconds since 1989 vs 1970)
      expect(fitTimestamp, greaterThan(unixTimestamp));
      
      print('✅ Current time: $now');
      print('✅ FIT timestamp: $fitTimestamp seconds since 1989');
      print('✅ Unix timestamp: $unixTimestamp seconds since 1970');
      print('✅ Difference: ${fitTimestamp - unixTimestamp} seconds (should be ~630720000)');
    });

    test('FIT file timestamp format should be correct', () {
      // Test with a known date
      final testDate = DateTime.utc(2024, 6, 8, 12, 0, 0);
      final fitTimestamp = toSecondsSince1989Epoch(testDate.millisecondsSinceEpoch);
      
      // Expected: seconds between Dec 31, 1989 and June 8, 2024
      final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
      final expectedSeconds = testDate.difference(fitEpoch).inSeconds;
      
      expect(fitTimestamp, equals(expectedSeconds));
      
      // Should not be showing 1970 dates (Unix timestamp would be much smaller)
      expect(fitTimestamp, greaterThan(1000000000)); // Should be way more than this
      
      print('✅ Test date: $testDate');
      print('✅ FIT timestamp: $fitTimestamp');
      print('✅ Expected: $expectedSeconds');
    });

    test('Basic FIT file creation should use correct timestamps', () {
      final builder = FitFileBuilder();
      
      // Create a simple file ID message
      final now = DateTime.now();
      final fileId = FileIdMessage()
        ..type = FileType.activity
        ..timeCreated = toSecondsSince1989Epoch(now.millisecondsSinceEpoch)
        ..manufacturer = Manufacturer.development.value;
      
      builder.add(fileId);
      
      // This should not throw and should create proper timestamps
      final fitFile = builder.build();
      final bytes = fitFile.toBytes();
      
      expect(bytes, isNotEmpty);
      expect(fileId.timeCreated, isNotNull);
      expect(fileId.timeCreated!, greaterThan(1000000000)); // Should be a large number
      
      print('✅ FIT file created with timestamp: ${fileId.timeCreated}');
      print('✅ File size: ${bytes.length} bytes');
    });

    test('Timestamp conversion consistency', () {
      final testDates = [
        DateTime.utc(2020, 1, 1),
        DateTime.utc(2023, 6, 15),
        DateTime.now(),
        DateTime.utc(2025, 12, 31),
      ];

      for (final date in testDates) {
        final fitTimestamp = toSecondsSince1989Epoch(date.millisecondsSinceEpoch);
        final unixTimestamp = date.millisecondsSinceEpoch ~/ 1000;
        
        // FIT timestamp should always be larger than Unix timestamp
        expect(fitTimestamp, greaterThan(unixTimestamp));
        
        // The difference should be approximately 630720000 seconds (19 years)
        final diff = fitTimestamp - unixTimestamp;
        expect(diff, closeTo(630720000, 86400)); // Within 1 day tolerance for leap years
        
        print('✅ Date: $date');
        print('   FIT: $fitTimestamp, Unix: $unixTimestamp, Diff: $diff');
      }
    });
  });
}
