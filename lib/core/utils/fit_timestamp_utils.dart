/// Utility functions for FIT timestamp conversions
/// 
/// FIT format uses seconds since December 31, 1989, 00:00:00 UTC as the epoch.
/// This file provides conversion functions to work with this timestamp format.
library;

/// The FIT epoch: December 31, 1989, 00:00:00 UTC
final DateTime fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0);

/// Converts a DateTime to FIT timestamp format (seconds since FIT epoch)
int toFitTimestamp(DateTime dateTime) {
  return dateTime.difference(fitEpoch).inSeconds;
}

/// Converts a FIT timestamp (seconds since FIT epoch) back to DateTime
DateTime fromFitTimestamp(int fitTimestamp) {
  return fitEpoch.add(Duration(seconds: fitTimestamp));
}

/// Converts milliseconds since Unix epoch to FIT timestamp (seconds since FIT epoch)
int millisecondsToFitTimestamp(int millisecondsSinceEpoch) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  return toFitTimestamp(dateTime);
}

/// Extension method for DateTime to easily convert to FIT timestamp
extension DateTimeToFit on DateTime {
  /// Converts this DateTime to FIT timestamp format (seconds since FIT epoch)
  int toFitTimestamp() {
    return difference(fitEpoch).inSeconds;
  }
}
