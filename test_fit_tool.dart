import 'package:fit_tool/fit_tool.dart';

void main() {
  // Test basic fit_tool API
  print('Testing fit_tool...');
  
  try {
    final fitFile = FitFile();
    print('FitFile created successfully');
    
    // Test available builders
    print('Testing FileId...');
    final fileId = FileId();
    print('FileId created');
    
    print('Testing Activity...');
    final activity = Activity();
    print('Activity created');
    
    print('Testing Session...');
    final session = Session();
    print('Session created');
    
    print('Testing Lap...');
    final lap = Lap();
    print('Lap created');
    
    print('Testing Record...');
    final record = Record();
    print('Record created');
    
  } catch (e) {
    print('Error: $e');
  }
}
