import 'package:fit_tool/fit_tool.dart';

void main() {
  // Explore the correct fit_tool API
  print('Available classes and methods in fit_tool:');
  
  // Try to create a FIT file
  var builder = FitFileBuilder();
  print('FitFileBuilder created: $builder');
  
  // Check available activity types
  print('Sport.training: ${Sport.training}');
  print('Sport.cycling: ${Sport.cycling}');
  print('Sport.rowing: ${Sport.rowing}');
  
  // Test creating messages
  var fileIdMessage = FileIdMessage();
  fileIdMessage.type = FileType.activity;
  print('FileIdMessage created: $fileIdMessage');
  
  var activityMessage = ActivityMessage();
  // activityMessage.type = ActivityType.manual;  // This might not exist
  print('ActivityMessage created: $activityMessage');
  print('ActivityMessage available fields: ${activityMessage.toString()}');
  
  var sessionMessage = SessionMessage();
  sessionMessage.sport = Sport.training;
  print('SessionMessage created: $sessionMessage');
  
  var recordMessage = RecordMessage();
  recordMessage.heartRate = 120;
  print('RecordMessage created: $recordMessage');
}
