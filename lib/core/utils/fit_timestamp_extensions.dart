/// FIT file timestamp utilities
/// 
/// FIT files use seconds since December 31, 1989 00:00:00 UTC as their epoch,
/// not Unix epoch (January 1, 1970). This file provides utilities to convert
/// between DateTime and FIT timestamps correctly.

// Convert DateTime to FIT format (seconds since 1989-12-31)
int toSecondsSince1989Epoch(DateTime dateTime) {
  const fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  return dateTime.difference(fitEpoch).inSeconds;
}

// Convert FIT timestamp back to DateTime
DateTime fromSecondsSince1989Epoch(int fitTimestamp) {
  const fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  return fitEpoch.add(Duration(seconds: fitTimestamp));
}

// Extension method for DateTime to make it easier to use
extension DateTimeExtension on DateTime {
  int toSecondsSince1989Epoch() {
    const fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
    return difference(fitEpoch).inSeconds;
  }
}
