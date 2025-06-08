import 'dart:io';
import 'package:fit_tool/fit_tool.dart';
import 'lib/src/fit_file_builder.dart';

void main() async {
  print('Testing FIT file timestamp validation...');
  
  // Test 1: Create a simple FIT file and verify timestamps
  await testSimpleFitFileTimestamps();
  
  // Test 2: Verify timestamp conversion functions
  testTimestampConversions();
  
  print('\nAll timestamp validation tests completed!');
}

Future<void> testSimpleFitFileTimestamps() async {
  print('\n=== Test 1: Simple FIT File Timestamp Validation ===');
  
  try {
    final builder = FitFileBuilder();
    final now = DateTime.now();
    final startTime = now.subtract(Duration(minutes: 30));
    
    print('Current time: $now');
    print('Session start time: $startTime');
    
    // Generate a simple workout
    final workoutData = [
      {'time': startTime, 'power': 150, 'cadence': 80},
      {'time': startTime.add(Duration(minutes: 10)), 'power': 200, 'cadence': 85},
      {'time': startTime.add(Duration(minutes: 20)), 'power': 180, 'cadence': 82},
      {'time': startTime.add(Duration(minutes: 30)), 'power': 160, 'cadence': 78},
    ];
    
    final fitBytes = builder.createWorkoutFitFile(
      workoutData: workoutData,
      startTime: startTime,
      sessionName: 'Timestamp_Test',
    );
    
    // Write to file for inspection
    final file = File('timestamp_test.fit');
    await file.writeAsBytes(fitBytes);
    print('Test FIT file created: ${file.path}');
    
    // Read and validate the FIT file
    final reader = FitFileReader();
    final fitFile = reader.read(fitBytes);
    
    bool hasValidTimestamps = true;
    
    // Check File ID message
    for (final record in fitFile.records) {
      if (record.globalMessageNum == GlobalMessageNum.fileId) {
        final fileIdMessage = FileIdMessage.fromRecord(record);
        final timeCreated = fileIdMessage.timeCreated;
        if (timeCreated != null) {
          final convertedTime = fromSecondsSince1989Epoch(timeCreated);
          print('File ID time_created: $timeCreated -> $convertedTime');
          
          // Should be close to start time (within 1 minute)
          final diff = convertedTime.difference(startTime).abs();
          if (diff.inMinutes > 1) {
            print('ERROR: File ID timestamp is too far from expected time');
            hasValidTimestamps = false;
          }
        }
      }
      
      // Check Session message
      if (record.globalMessageNum == GlobalMessageNum.session) {
        final sessionMessage = SessionMessage.fromRecord(record);
        final sessionTimestamp = sessionMessage.timestamp;
        final sessionStartTime = sessionMessage.startTime;
        
        if (sessionTimestamp != null) {
          final convertedTime = fromSecondsSince1989Epoch(sessionTimestamp);
          print('Session timestamp: $sessionTimestamp -> $convertedTime');
          
          // Should be close to end time
          final expectedEndTime = startTime.add(Duration(minutes: 30));
          final diff = convertedTime.difference(expectedEndTime).abs();
          if (diff.inMinutes > 1) {
            print('ERROR: Session timestamp is too far from expected end time');
            hasValidTimestamps = false;
          }
        }
        
        if (sessionStartTime != null) {
          final convertedStartTime = fromSecondsSince1989Epoch(sessionStartTime);
          print('Session start_time: $sessionStartTime -> $convertedStartTime');
          
          // Should be close to start time
          final diff = convertedStartTime.difference(startTime).abs();
          if (diff.inMinutes > 1) {
            print('ERROR: Session start time is too far from expected start time');
            hasValidTimestamps = false;
          }
        }
      }
      
      // Check Record messages
      if (record.globalMessageNum == GlobalMessageNum.record) {
        final recordMessage = RecordMessage.fromRecord(record);
        final recordTimestamp = recordMessage.timestamp;
        
        if (recordTimestamp != null) {
          final convertedTime = fromSecondsSince1989Epoch(recordTimestamp);
          print('Record timestamp: $recordTimestamp -> $convertedTime');
          
          // Should be between start and end time
          if (convertedTime.isBefore(startTime) || 
              convertedTime.isAfter(startTime.add(Duration(minutes: 35)))) {
            print('ERROR: Record timestamp is outside expected range');
            hasValidTimestamps = false;
          }
        }
      }
    }
    
    if (hasValidTimestamps) {
      print('✅ All timestamps are valid and in expected ranges');
    } else {
      print('❌ Some timestamps are invalid');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error in timestamp validation test: $e');
    print(stackTrace);
  }
}

void testTimestampConversions() {
  print('\n=== Test 2: Timestamp Conversion Functions ===');
  
  final testDates = [
    DateTime(1989, 12, 31, 0, 0, 0), // FIT epoch
    DateTime(2024, 1, 1, 12, 0, 0),  // Recent date
    DateTime.now(),                   // Current time
  ];
  
  for (final date in testDates) {
    print('\nTesting date: $date');
    
    // Test milliseconds conversion
    final fitTimestamp = date.toSecondsSince1989Epoch();
    final convertedBack = fromSecondsSince1989Epoch(fitTimestamp);
    
    print('Original: $date');
    print('FIT timestamp: $fitTimestamp');
    print('Converted back: $convertedBack');
    
    // Check if conversion is accurate (within 1 second)
    final diff = convertedBack.difference(date).abs();
    if (diff.inSeconds <= 1) {
      print('✅ Conversion accurate');
    } else {
      print('❌ Conversion inaccurate - difference: ${diff.inSeconds} seconds');
    }
    
    // Verify it's not a Unix epoch timestamp (which would be huge)
    if (fitTimestamp > 2000000000) {
      print('❌ Warning: Timestamp looks like Unix epoch!');
    } else {
      print('✅ Timestamp is in FIT format');
    }
  }
}

// Helper function to convert FIT timestamp back to DateTime for validation
DateTime fromSecondsSince1989Epoch(int fitTimestamp) {
  final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  return fitEpoch.add(Duration(seconds: fitTimestamp));
}

// Extension method for conversion (same as in the main code)
extension DateTimeExtension on DateTime {
  int toSecondsSince1989Epoch() {
    final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
    return difference(fitEpoch).inSeconds;
  }
}
