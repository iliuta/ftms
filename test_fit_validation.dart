import 'dart:io';
import 'dart:typed_data';
import 'package:fit_tool/fit_tool.dart';
import 'package:flutter_ftms/flutter_ftms.dart';

// Mock classes for testing since this is running outside Flutter context
class MockTrainingRecord {
  final DateTime timestamp;
  final int elapsedTime;
  final int? instantaneousPower;
  final double? instantaneousSpeed;
  final int? instantaneousCadence;
  final int? heartRate;
  final double? totalDistance;

  MockTrainingRecord({
    required this.timestamp,
    required this.elapsedTime,
    this.instantaneousPower,
    this.instantaneousSpeed,
    this.instantaneousCadence,
    this.heartRate,
    this.totalDistance,
  });
}

Future<List<int>> createTestFitFile() async {
  final builder = FitFileBuilder();
  final now = DateTime.now();
  final sessionStart = now.subtract(Duration(minutes: 10));

  // Create some test records
  final records = <MockTrainingRecord>[];
  for (int i = 0; i < 10; i++) {
    records.add(MockTrainingRecord(
      timestamp: sessionStart.add(Duration(seconds: i * 60)),
      elapsedTime: i * 60,
      instantaneousPower: 200 + (i * 10),
      instantaneousSpeed: 25.0 + (i * 0.5),
      instantaneousCadence: 80 + i,
      heartRate: 140 + i,
      totalDistance: (i * 100).toDouble(),
    ));
  }

  // Create File ID message
  final fileIdMessage = FileIdMessage()
    ..type = FileType.activity
    ..timeCreated = toSecondsSince1989Epoch(sessionStart.millisecondsSinceEpoch)
    ..manufacturer = Manufacturer.development.value;

  // Create Activity message
  final activityMessage = ActivityMessage()
    ..timestamp = toSecondsSince1989Epoch(records.last.timestamp.millisecondsSinceEpoch)
    ..type = Activity.manual
    ..totalTimerTime = (records.last.elapsedTime * 1000).toDouble();

  // Create Session message
  final sessionMessage = SessionMessage()
    ..timestamp = toSecondsSince1989Epoch(records.last.timestamp.millisecondsSinceEpoch)
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
    ..startTime = toSecondsSince1989Epoch(sessionStart.millisecondsSinceEpoch)
    ..totalElapsedTime = (records.last.elapsedTime * 1000).toDouble()
    ..totalTimerTime = (records.last.elapsedTime * 1000).toDouble();

  // Create Lap message
  final lapMessage = LapMessage()
    ..timestamp = toSecondsSince1989Epoch(records.last.timestamp.millisecondsSinceEpoch)
    ..startTime = toSecondsSince1989Epoch(sessionStart.millisecondsSinceEpoch)
    ..totalElapsedTime = (records.last.elapsedTime * 1000).toDouble()
    ..totalTimerTime = (records.last.elapsedTime * 1000).toDouble();

  // Add all messages to builder
  builder.add(fileIdMessage);
  builder.add(activityMessage);
  builder.add(sessionMessage);
  builder.add(lapMessage);

  // Create Record messages for each data point
  for (final record in records) {
    final recordMessage = RecordMessage()
      ..timestamp = toSecondsSince1989Epoch(record.timestamp.millisecondsSinceEpoch)
      ..power = record.instantaneousPower?.round()
      ..speed = record.instantaneousSpeed != null 
          ? (record.instantaneousSpeed! / 3.6 * 1000).toDouble() // Convert km/h to mm/s
          : null
      ..cadence = record.instantaneousCadence?.round()
      ..heartRate = record.heartRate?.round()
      ..distance = record.totalDistance?.toDouble();

    builder.add(recordMessage);
  }

  final fitFile = builder.build();
  return fitFile.toBytes();
}

void main() async {
  print('Testing FIT file generation with corrected timestamps...');
  
  try {
    // Create FIT file
    final bytes = await createTestFitFile();
    
    // Write to file
    final file = File('test_validation_output.fit');
    await file.writeAsBytes(bytes);
    
    print('FIT file generated: ${file.path}');
    print('FIT file size: ${bytes.length} bytes');
    
    // Try to parse the FIT file
    final fitFile = FitFile.fromBytes(bytes);
    print('FIT file parsed successfully!');
    
    // Check messages
    int recordCount = 0;
    DateTime? firstTimestamp;
    DateTime? lastTimestamp;
    
    for (final message in fitFile.messages) {
      if (message is RecordMessage) {
        recordCount++;
        if (message.timestamp != null) {
          final timestamp = fromSecondsSince1989Epoch(message.timestamp!);
          if (firstTimestamp == null || timestamp.isBefore(firstTimestamp)) {
            firstTimestamp = timestamp;
          }
          if (lastTimestamp == null || timestamp.isAfter(lastTimestamp)) {
            lastTimestamp = timestamp;
          }
        }
      } else if (message is FileIdMessage) {
        if (message.timeCreated != null) {
          final created = fromSecondsSince1989Epoch(message.timeCreated!);
          print('File created timestamp: $created');
        }
      } else if (message is SessionMessage) {
        if (message.startTime != null) {
          final startTime = fromSecondsSince1989Epoch(message.startTime!);
          print('Session start time: $startTime');
        }
        if (message.timestamp != null) {
          final endTime = fromSecondsSince1989Epoch(message.timestamp!);
          print('Session end time: $endTime');
        }
      }
    }
    
    print('Found $recordCount record messages');
    if (firstTimestamp != null && lastTimestamp != null) {
      print('First record timestamp: $firstTimestamp');
      print('Last record timestamp: $lastTimestamp');
      print('Session duration: ${lastTimestamp.difference(firstTimestamp).inSeconds} seconds');
    }
    
    // Check if timestamps are reasonable (not in the year 2106)
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    final tomorrow = now.add(Duration(days: 1));
    
    bool timestampsValid = true;
    if (firstTimestamp != null) {
      if (firstTimestamp.isBefore(yesterday) || firstTimestamp.isAfter(tomorrow)) {
        print('WARNING: First timestamp appears invalid: $firstTimestamp');
        timestampsValid = false;
      }
    }
    if (lastTimestamp != null) {
      if (lastTimestamp.isBefore(yesterday) || lastTimestamp.isAfter(tomorrow)) {
        print('WARNING: Last timestamp appears invalid: $lastTimestamp');
        timestampsValid = false;
      }
    }
    
    if (timestampsValid) {
      print('✅ All timestamps appear valid and recent!');
    } else {
      print('❌ Some timestamps appear invalid');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('FIT validation test completed.');
}
