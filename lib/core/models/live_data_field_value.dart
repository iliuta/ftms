import 'package:flutter_ftms/flutter_ftms.dart';

/// Holder for a live data field value coming from the FTMS device.
class LiveDataFieldValue {
  final String name;
  final num value;
  final num factor;
  final String unit;
  final bool? flag;
  final int size;
  final bool signed;

  const LiveDataFieldValue({
    required this.name,
    required this.value,
    this.factor = 1,
    this.unit = '',
    this.flag,
    this.size = 2,
    this.signed = false,
  });

  /// Create an FtmsParameter from a DeviceDataParameterValue
  factory LiveDataFieldValue.fromDeviceDataParameterValue(DeviceDataParameterValue paramValue) {
    return LiveDataFieldValue(
      name: paramValue.name.name,
      value: paramValue.value,
      factor: paramValue.factor,
      unit: paramValue.unit,
      flag: _getFlag(paramValue),
      size: paramValue.size,
      signed: paramValue.signed,
    );
  }

  /// Create a new FtmsParameter with a different value (for averaging)
  LiveDataFieldValue copyWith({
    String? name,
    num? value,
    num? factor,
    String? unit,
    bool? flag,
    int? size,
    bool? signed,
  }) {
    return LiveDataFieldValue(
      name: name ?? this.name,
      value: value ?? this.value,
      factor: factor ?? this.factor,
      unit: unit ?? this.unit,
      flag: flag ?? this.flag,
      size: size ?? this.size,
      signed: signed ?? this.signed,
    );
  }

  /// Get the scaled value using the factor
  num getScaledValue() {
    return value * factor;
  }

  /// Check if this parameter's scaled value is within target range (±10%)
  bool isWithinTarget(num? target) {
    if (target == null) return false;
    final scaledValue = getScaledValue();
    final lower = target * 0.9;
    final upper = target * 1.1;
    return scaledValue >= lower && scaledValue <= upper;
  }

  /// Get the value formatted for display
  String getFormattedValue() {
    return '$value $unit';
  }

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveDataFieldValue &&
        other.name == name &&
        other.value == value &&
        other.factor == factor &&
        other.unit == unit &&
        other.flag == flag &&
        other.size == size &&
        other.signed == signed;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      value,
      factor,
      unit,
      flag,
      size,
      signed,
    );
  }

  /// Helper method to safely extract flag from FTMS parameter
  static bool? _getFlag(dynamic param) {
    try {
      if (param.flag != null) {
        return param.flag is bool ? param.flag : null;
      }
    } catch (e) {
      // Ignore and fall back to null
    }
    return null;
  }
}
