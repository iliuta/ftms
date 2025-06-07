import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ftms/flutter_ftms.dart';


class FtmsDisplayField {
  final String name;
  final String label;
  final String display;
  final String unit;
  final num? min;
  final num? max;
  final String? icon;
  FtmsDisplayField({
    required this.name,
    required this.label,
    required this.display,
    required this.unit,
    this.min,
    this.max,
    this.icon,
  });
  factory FtmsDisplayField.fromJson(Map<String, dynamic> json) {
    return FtmsDisplayField(
      name: json['name'] as String,
      label: json['label'] as String,
      display: json['display'] as String? ?? 'number',
      unit: json['unit'] as String? ?? '',
      min: json['min'] as num?,
      max: json['max'] as num?,
      icon: json['icon'] as String?,
    );
  }
}


class FtmsDisplayConfig {
  final List<FtmsDisplayField> fields;
  FtmsDisplayConfig({required this.fields});

  factory FtmsDisplayConfig.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List<dynamic>?;
    if (fieldsJson == null) {
      throw Exception('No fields in config');
    }
    final fields = fieldsJson
        .map((f) => FtmsDisplayField.fromJson(f as Map<String, dynamic>))
        .toList();
    return FtmsDisplayConfig(fields: fields);
  }
}

Future<FtmsDisplayConfig?> loadFtmsDisplayConfig(DeviceDataType type) async {
  String? configFile;
  switch (type) {
    case DeviceDataType.rower:
      configFile = 'lib/config/rowing_machine.json';
      break;
    case DeviceDataType.indoorBike:
      configFile = 'lib/config/indoor_bike.json';
      break;
    default:
      return null;
  }
  try {
    final jsonStr = await rootBundle.loadString(configFile);
    final jsonData = json.decode(jsonStr);
    final fieldsJson = jsonData['fields'] as List<dynamic>?;
    if (fieldsJson == null) throw Exception('No fields in config');
    final fields = [for (final f in fieldsJson) FtmsDisplayField.fromJson(f as Map<String, dynamic>)];
    return FtmsDisplayConfig(fields: fields);
  } catch (e) {
    return null;
  }
}
