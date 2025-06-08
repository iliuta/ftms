class FtmsDisplayField {
  final String name;
  final String label;
  final String display;
  final String? formatter;
  final String unit;
  final num? min;
  final num? max;
  final String? icon;
  final int? samplePeriodSeconds;
  FtmsDisplayField({
    required this.name,
    required this.label,
    required this.display,
    this.formatter,
    required this.unit,
    this.min,
    this.max,
    this.icon,
    this.samplePeriodSeconds,
  });
  factory FtmsDisplayField.fromJson(Map<String, dynamic> json) {
    return FtmsDisplayField(
      name: json['name'] as String,
      label: json['label'] as String,
      display: json['display'] as String? ?? 'number',
      formatter: json['formatter'] as String?,
      unit: json['unit'] as String? ?? '',
      min: json['min'] as num?,
      max: json['max'] as num?,
      icon: json['icon'] as String?,
      samplePeriodSeconds: json['samplePeriodSeconds'] as int?,
    );
  }
}