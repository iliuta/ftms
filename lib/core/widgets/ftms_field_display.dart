import 'package:flutter/material.dart';
import '../models/ftms_display_field.dart';
import '../models/ftms_parameter.dart';
import 'ftms_display_widget_registry.dart';

/// Widget for displaying a single FTMS field.
class FtmsFieldDisplay extends StatelessWidget {
  final FtmsDisplayField field;
  final FtmsParameter? param;
  final dynamic target;
  final Color? defaultColor;
  final String? machineType;

  const FtmsFieldDisplay({
    super.key,
    required this.field,
    required this.param,
    this.target,
    this.defaultColor,
    this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    Color? color = defaultColor;
    if (param == null) {
      return Text('${field.label}: (not available)', style: const TextStyle(color: Colors.grey));
    }
    
    final value = param!.value;
    final factor = param!.factor;

    color = _getFieldColor(value, factor, color);

    final widgetBuilder = ftmsDisplayWidgetRegistry[field.display];
    if (widgetBuilder != null) {
      return widgetBuilder(
        displayField: field,
        param: param!,
        color: color
      );
    }
    return Text('${field.label}: (unknown display type)', style: const TextStyle(color: Colors.red));
  }

  Color? _getFieldColor(dynamic value, num factor, Color? color) {
    if (target != null && param != null) {
      final targetValue = target is num ? target : num.tryParse(target.toString());
      if (param!.isWithinTarget(targetValue)) {
        color = Colors.green[700];
      } else {
        color = Colors.red[700];
      }
    }
    return color;
  }
}
