import 'package:flutter/material.dart';
import 'simple_number_widget.dart';
import 'speedometer_widget.dart';
import 'ftms_live_data_display_widget.dart';

/// Dictionary of available FTMS display widgets for use in config files.
/// Maps display type string to a builder function.
typedef FtmsWidgetBuilder = Widget Function({
  required String label,
  required num value,
  required String unit,
  String? icon,
  Color? color,
  double? min,
  double? max,
});

final Map<String, FtmsWidgetBuilder> ftmsDisplayWidgetRegistry = {
  'number': ({
    required String label,
    required num value,
    required String unit,
    String? icon,
    Color? color,
    double? min,
    double? max,
  }) => SimpleNumberWidget(
    label: label,
    value: value,
    unit: unit,
    icon: icon,
    color: color,
  ),
  'speedometer': ({
    required String label,
    required num value,
    required String unit,
    String? icon,
    Color? color,
    double? min,
    double? max,
  }) => SpeedometerWidget(
    value: value.toDouble(),
    min: min ?? 0,
    max: max ?? 100,
    label: label,
    unit: unit,
    color: color ?? Colors.blue,
  ),
};
