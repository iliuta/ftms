import 'package:flutter_test/flutter_test.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:ftms/core/utils/fit_timestamp_utils.dart';

void main() {
  group('Timestamp Validation Tests', () {
    test('millisecondsToFitTimestamp function should work correctly', () {
      // Test with a known date
      final testDate = DateTime.utc(2024, 6, 8, 12, 0, 0);
      final fitTimestamp = millisecondsToFitTimestamp(testDate.millisecondsSinceEpoch);
      
      // Expected: milliseconds between Dec 31, 1989 and June 8, 2024
      final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
      final expectedMilliSeconds = testDate.difference(fitEpoch).inMilliseconds;
      
      expect(fitTimestamp, equals(expectedMilliSeconds));
      
      // Verify it's not a Unix timestamp (which would be huge)
      final unixTimestamp = testDate.millisecondsSinceEpoch;
      expect(fitTimestamp, isNot(equals(unixTimestamp)));
      
      // FIT timestamp should be smaller than Unix timestamp (FIT epoch is later than Unix epoch)
      expect(fitTimestamp, lessThan(unixTimestamp));
    });

    test('FIT file timestamp format should be correct', () {
      // Create a simple FileIdMessage and verify timestamp format
      final now = DateTime.now();
      final fitTimestamp = millisecondsToFitTimestamp(now.millisecondsSinceEpoch);
      
      // Expected: milliseconds between Dec 31, 1989 and now
      final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
      final expectedMilliSeconds = now.difference(fitEpoch).inMilliseconds;
      
      expect(fitTimestamp, equals(expectedMilliSeconds));
      
      // Should be a reasonable number representing milliseconds since FIT epoch
      expect(fitTimestamp, greaterThan(1000000000000)); // Should be over 1 trillion milliseconds since 1989
    });
    
    test('Basic FIT file creation should use correct timestamps', () {
      final builder = FitFileBuilder();
      final now = DateTime.now();
      
      // Create File ID message
      final fileIdMessage = FileIdMessage()
        ..type = FileType.activity
        ..timeCreated = millisecondsToFitTimestamp(now.millisecondsSinceEpoch)
        ..manufacturer = Manufacturer.development.value;
      
      builder.add(fileIdMessage);
      final fitFile = builder.build();
      final bytes = fitFile.toBytes();
      
      expect(bytes, isNotEmpty);
      expect(fileIdMessage.timeCreated, isNotNull);
      expect(fileIdMessage.timeCreated!, greaterThan(1000000000000)); // Should be over 1 trillion milliseconds since 1989
    });

    test('Timestamp conversion consistency', () {
      final dates = [
        DateTime.utc(1989, 12, 31, 0, 0, 0), // FIT epoch
        DateTime.utc(2024, 1, 1, 0, 0, 0),   // Recent date
        DateTime.now(),                       // Current time
      ];
      
      for (final date in dates) {
        final fitTimestamp = millisecondsToFitTimestamp(date.millisecondsSinceEpoch);
        final unixTimestamp = date.millisecondsSinceEpoch;
        
        // FIT timestamp should be smaller than Unix timestamp (FIT epoch is later than Unix epoch)
        expect(fitTimestamp, lessThan(unixTimestamp));
        
        // The difference should be approximately 631065600000 milliseconds (Unix - FIT, since Unix has more milliseconds)
        final diff = unixTimestamp - fitTimestamp; // Unix - FIT should be positive
        expect(diff, closeTo(631065600000, 86400000)); // Within 1 day tolerance for leap years
      }
    });
  });
}
