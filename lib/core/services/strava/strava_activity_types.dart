/// Common Strava activity types for fitness activities
/// 
/// These are the most commonly used activity types in Strava.
/// You can use these constants when uploading activities to ensure
/// they are categorized correctly.
class StravaActivityTypes {
  static const String ride = 'ride';
  static const String run = 'run';
  static const String swimming = 'swim';
  static const String rowing = 'rowing';
  static const String workout = 'workout';
  static const String walk = 'walk';
  static const String hike = 'hike';
  static const String virtualRide = 'virtualride';
  static const String yoga = 'yoga';
  static const String weightTraining = 'weighttraining';
  static const String crossfit = 'crossfit';
  static const String elliptical = 'elliptical';
  static const String stairStepper = 'stairstepper';
  
  /// List of all available activity types
  static const List<String> all = [
    ride,
    run,
    swimming,
    rowing,
    workout,
    walk,
    hike,
    virtualRide,
    yoga,
    weightTraining,
    crossfit,
    elliptical,
    stairStepper,
  ];
  
  /// Check if an activity type is valid
  static bool isValid(String activityType) {
    return all.contains(activityType);
  }
}
