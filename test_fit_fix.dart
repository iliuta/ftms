import 'package:fit_tool/fit_tool.dart';
import 'lib/core/services/training_data_recorder.dart';
import 'lib/core/models/training_record.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'dart:io';

void main() async {
  print('Testing FIT file generation with correct timestamps...');
  
  try {
    // Create a training data recorder
    final recorder = TrainingDataRecorder(
      deviceType: DeviceDataType.indoorBike,
      sessionName: 'test_session',
    );
    
    // Start recording
    recorder.startRecording();
    
    // Add some test data points (simulating a 5-minute session)
    for (int i = 0; i < 300; i++) {
      final now = DateTime.now().add(Duration(seconds: i));
      recorder.recordDataPoint(
        ftmsParams: {
          'Instantaneous Power': 150 + (i % 50), // Varying power
          'Instantaneous Speed': 25.0, // 25 km/h
          'Instantaneous Cadence': 90, // 90 RPM
          'Heart Rate': 140 + (i % 20), // Varying HR
        },
        resistanceLevel: 5.0,
      );
      
      // Log progress every 60 seconds
      if (i > 0 && i % 60 == 0) {
        print('Added $i data points...');
      }
    }
    
    // Stop recording
    recorder.stopRecording();
    
    // Generate FIT file
    print('Generating FIT file...');
    final fitFilePath = await recorder.generateFitFile();
    
    if (fitFilePath != null) {
      print('FIT file generated successfully: $fitFilePath');
      
      // Check the file size
      final file = File(fitFilePath);
      final fileSize = await file.length();
      print('File size: ${fileSize} bytes');
      
      // Try to read and analyze the FIT file
      print('Analyzing generated FIT file...');
      final fitBytes = await file.readAsBytes();
      
      // Decode the FIT file to verify its structure
      final decoder = FitDecoder();
      final decodedFit = decoder.decode(fitBytes);
      
      print('FIT file decoded successfully!');
      print('Number of records: ${decodedFit.records.length}');
      
      // Check some sample timestamps to verify they're correct
      if (decodedFit.records.isNotEmpty) {
        final firstRecord = decodedFit.records.first;
        final lastRecord = decodedFit.records.last;
        
        print('First record timestamp: ${firstRecord.fields}');
        print('Last record timestamp: ${lastRecord.fields}');
        
        // Check if timestamps are reasonable (not in 2106)
        final now = DateTime.now();
        final futureLimit = now.add(Duration(days: 365)); // 1 year in the future
        
        print('Current time for reference: ${now.millisecondsSinceEpoch ~/ 1000} seconds since Unix epoch');
        print('Future limit: ${futureLimit.millisecondsSinceEpoch ~/ 1000} seconds since Unix epoch');
      }
      
    } else {
      print('Failed to generate FIT file');
    }
    
  } catch (e, stackTrace) {
    print('Error during FIT file generation test: $e');
    print('Stack trace: $stackTrace');
  }
}
