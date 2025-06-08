import 'package:flutter_ftms/flutter_ftms.dart';

/// Model class representing an FTMS parameter with all its properties
/// This replaces the dynamic param usage throughout the codebase
class FtmsParameter {
  final String name;
  final num value;
  final num factor;
  final String unit;
  final num scaleFactor;
  final bool? flag;
  final int size;
  final bool signed;

  const FtmsParameter({
    required this.name,
    required this.value,
    this.factor = 1,
    this.unit = '',
    this.scaleFactor = 1,
    this.flag,
    this.size = 2,
    this.signed = false,
  });

  /// Create an FtmsParameter from a DeviceDataParameterValue
  factory FtmsParameter.fromDeviceDataParameterValue(DeviceDataParameterValue paramValue) {
    return FtmsParameter(
      name: paramValue.name.name,
      value: paramValue.value,
      factor: paramValue.factor,
      unit: paramValue.unit,
      scaleFactor: _getScaleFactor(paramValue),
      flag: _getFlag(paramValue),
      size: paramValue.size,
      signed: paramValue.signed,
    );
  }

  /// Create a new FtmsParameter with a different value (for averaging)
  FtmsParameter copyWith({
    String? name,
    num? value,
    num? factor,
    String? unit,
    num? scaleFactor,
    bool? flag,
    int? size,
    bool? signed,
  }) {
    return FtmsParameter(
      name: name ?? this.name,
      value: value ?? this.value,
      factor: factor ?? this.factor,
      unit: unit ?? this.unit,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      flag: flag ?? this.flag,
      size: size ?? this.size,
      signed: signed ?? this.signed,
    );
  }

  /// Get the scaled value using the scale factor
  num getScaledValue() {
    return value * scaleFactor;
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
    return other is FtmsParameter &&
        other.name == name &&
        other.value == value &&
        other.factor == factor &&
        other.unit == unit &&
        other.scaleFactor == scaleFactor &&
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
      scaleFactor,
      flag,
      size,
      signed,
    );
  }

  /// Helper method to safely extract scaleFactor from FTMS parameter
  static num _getScaleFactor(dynamic param) {
    try {
      // Try different ways to access scaleFactor based on FTMS library implementation
      if (param.scaleFactor != null) {
        return param.scaleFactor;
      }
    } catch (e) {
      // Ignore and fall back to default
    }
    return 1;
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
