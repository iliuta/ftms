import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:ftms/core/services/training_data_recorder.dart';

void main() async {
  print('Testing FIT file generation...');
  
  // Create a training data recorder
  final recorder = TrainingDataRecorder(
    deviceType: DeviceDataType.indoorBike,
    sessionName: 'TestSession'
  );
  
  print('Starting recording...');
  recorder.startRecording();
  
  // Add some test data points
  for (int i = 0; i < 10; i++) {
    await Future.delayed(Duration(milliseconds: 100));
    
    recorder.recordDataPoint(
      ftmsParams: {
        'Instantaneous Power': 150 + (i * 5),
        'Instantaneous Speed': 25.0 + (i * 0.5),
        'Instantaneous Cadence': 80 + i,
        'Heart Rate': 140 + i,
      },
      resistanceLevel: 5.0,
    );
  }
  
  print('Stopping recording...');
  recorder.stopRecording();
  
  print('Statistics: ${recorder.getStatistics()}');
  
  // Generate FIT file
  print('Generating FIT file...');
  final fitPath = await recorder.generateFitFile();
  
  if (fitPath != null) {
    print('✅ FIT file generated successfully: $fitPath');
  } else {
    print('❌ Failed to generate FIT file');
  }
}
