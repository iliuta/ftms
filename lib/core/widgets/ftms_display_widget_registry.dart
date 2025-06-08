import 'package:flutter/material.dart';
import '../models/ftms_display_field.dart';
import '../models/ftms_parameter.dart';
import 'simple_number_widget.dart';
import 'speedometer_widget.dart';

/// Dictionary of available FTMS display widgets for use in config files.
/// Maps display type string to a builder function.
typedef FtmsWidgetBuilder = Widget Function(
    {required FtmsDisplayField displayField, FtmsParameter? param, Color? color});

final Map<String, FtmsWidgetBuilder> ftmsDisplayWidgetRegistry = {
  'number': ({required displayField, param, color}) =>
      SimpleNumberWidget(displayField, param!, color),
  'speedometer': ({required displayField, param, color}) => SpeedometerWidget(
        displayField: displayField,
        param: param,
        color: color ?? Colors.blue,
      ),
};
