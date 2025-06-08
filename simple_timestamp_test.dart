// Simple timestamp validation script
void main() {
  print('=== FIT Timestamp Validation ===');
  
  // Test the timestamp conversion function
  testTimestampConversion();
  
  // Verify our fixes are working
  verifyTimestampFixes();
}

void testTimestampConversion() {
  print('\n1. Testing timestamp conversion function:');
  
  final testDates = [
    DateTime(1989, 12, 31, 0, 0, 0), // FIT epoch
    DateTime(2024, 1, 1, 12, 0, 0),  // Recent date
    DateTime.now(),                   // Current time
  ];
  
  for (final date in testDates) {
    final fitTimestamp = date.toSecondsSince1989Epoch();
    final convertedBack = fromSecondsSince1989Epoch(fitTimestamp);
    
    print('  Original: $date');
    print('  FIT timestamp: $fitTimestamp seconds');
    print('  Converted back: $convertedBack');
    
    // Verify it's not a Unix epoch timestamp (which would be huge)
    if (fitTimestamp > 2000000000) {
      print('  ❌ WARNING: Timestamp looks like Unix epoch!');
    } else {
      print('  ✅ Timestamp is in FIT format');
    }
    
    // Check accuracy
    final diff = convertedBack.difference(date).abs();
    if (diff.inSeconds <= 1) {
      print('  ✅ Conversion accurate\n');
    } else {
      print('  ❌ Conversion inaccurate - difference: ${diff.inSeconds} seconds\n');
    }
  }
}

void verifyTimestampFixes() {
  print('2. Verifying timestamp fixes:');
  
  final now = DateTime.now();
  
  // Test what the old (incorrect) conversion would produce
  final oldUnixEpochMethod = now.millisecondsSinceEpoch ~/ 1000;
  
  // Test our new (correct) conversion
  final newFitMethod = now.toSecondsSince1989Epoch();
  
  print('  Current time: $now');
  print('  Old method (Unix epoch ÷ 1000): $oldUnixEpochMethod');
  print('  New method (FIT epoch): $newFitMethod');
  print('  Difference: ${oldUnixEpochMethod - newFitMethod} seconds');
  
  // Convert back to verify
  final oldMethodAsDate = DateTime.fromMillisecondsSinceEpoch(oldUnixEpochMethod * 1000);
  final newMethodAsDate = fromSecondsSince1989Epoch(newFitMethod);
  
  print('  Old method as date: $oldMethodAsDate');
  print('  New method as date: $newMethodAsDate');
  
  // Check if old method would result in 1970 dates in FIT readers
  final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  final oldMethodInFitFormat = fitEpoch.add(Duration(seconds: oldUnixEpochMethod));
  
  print('  Old method interpreted as FIT timestamp: $oldMethodInFitFormat');
  
  if (oldMethodInFitFormat.year < 2020) {
    print('  ❌ Old method would show incorrect dates (like 1970s)');
  }
  
  if (newMethodAsDate.difference(now).abs().inSeconds < 2) {
    print('  ✅ New method produces correct current dates');
  }
}

// Helper function to convert FIT timestamp back to DateTime
DateTime fromSecondsSince1989Epoch(int fitTimestamp) {
  final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  return fitEpoch.add(Duration(seconds: fitTimestamp));
}

// Extension method for FIT timestamp conversion
extension DateTimeExtension on DateTime {
  int toSecondsSince1989Epoch() {
    final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
    return difference(fitEpoch).inSeconds;
  }
}
