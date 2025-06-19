/// This class describes the configuration for live data fields in the app:
/// their name, their label to be used in the UI, how they should be displayed,
class LiveDataFieldConfig {
  /// The name of the field, corresponding to FTMS parameter names
  /// as specified in the FTMS library.
  /// Examples include 'Instantaneous Power', 'Heart Rate', etc.
  final String name;
  /// The label to be displayed in the UI for this field.
  final String label;
  /// The display type for this field, such as 'number', 'speedometer', etc.
  /// to be taken from widgets/frms_display_widget_registry.dart
  final String display;
  /// Optional formatter for the field value, used to format the value for display.
  /// For example, 'rowerPaceFormatter' for rower pace formatting.
  final String? formatter;
  /// The unit of measurement for this field, such as 'km/h', 'rpm', etc.
  final String unit;
  /// Optional minimum value for the field, used for validation or display purposes.
  final num? min;
  /// Optional maximum value for the field, used for validation or display purposes.
  final num? max;
  /// Optional icon name for the field, used in the UI to represent the field visually.
  /// the values are defined in ftmsIconRegistry
  final String? icon;
  /// Optional sample period in seconds for the field. Useful for fields that
  /// require averaging over a period of time, such as power.
  final int? samplePeriodSeconds;
  /// Whether this field is available as a target in training sessions.
  /// When true, this field can be used to set target values during workouts.
  final bool availableAsTarget;
  /// Optional reference to the corresponding user setting key.
  /// This links the field to a specific user setting for training purposes.
  /// For example, 'rowingFtp' for rowing FTP or 'cyclingFtp' for cycling FTP.
  final String? userSetting;

  LiveDataFieldConfig({
    required this.name,
    required this.label,
    required this.display,
    this.formatter,
    required this.unit,
    this.min,
    this.max,
    this.icon,
    this.samplePeriodSeconds,
    this.availableAsTarget = false,
    this.userSetting,
  });
  factory LiveDataFieldConfig.fromJson(Map<String, dynamic> json) {
    return LiveDataFieldConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      display: json['display'] as String? ?? 'number',
      formatter: json['formatter'] as String?,
      unit: json['unit'] as String? ?? '',
      min: json['min'] as num?,
      max: json['max'] as num?,
      icon: json['icon'] as String?,
      samplePeriodSeconds: json['samplePeriodSeconds'] as int?,
      availableAsTarget: json['availableAsTarget'] as bool? ?? false,
      userSetting: json['userSetting'] as String?,
    );
  }
}