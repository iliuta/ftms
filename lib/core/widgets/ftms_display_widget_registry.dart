import 'package:flutter/material.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import 'simple_number_widget.dart';
import 'speedometer_widget.dart';

/// Dictionary of available FTMS display widgets for use in config files.
/// Maps display type string to a builder function.
typedef FtmsWidgetBuilder = Widget Function(
    {required FtmsDisplayField displayField, required dynamic param, Color? color});

final Map<String, FtmsWidgetBuilder> ftmsDisplayWidgetRegistry = {
  'number': ({required displayField, required dynamic param, color}) =>
      SimpleNumberWidget(displayField, param, color),
  'speedometer': ({required displayField, param, color}) => SpeedometerWidget(
        displayField: displayField,
        param: param,
        color: color ?? Colors.blue,
      ),
};
