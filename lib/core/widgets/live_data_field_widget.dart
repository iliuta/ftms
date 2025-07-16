import 'package:flutter/material.dart';
import 'package:ftms/core/models/device_types.dart';
import '../config/live_data_field_config.dart';
import '../models/live_data_field_value.dart';
import 'live_data_field_widget_registry.dart';

/// Widget for displaying a single FTMS field.
class LiveDataFieldWidget extends StatelessWidget {
  final LiveDataFieldConfig field;
  final LiveDataFieldValue? param;
  final dynamic target;
  final Color? defaultColor;
  final DeviceType? machineType;

  const LiveDataFieldWidget({
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

    final widgetBuilder = liveDataFieldWidgetRegistry[field.display];
    if (widgetBuilder != null) {
      // Compute target interval if target is available
      final targetValue = target is num ? target : num.tryParse(target?.toString() ?? '');
      final targetInterval = targetValue != null ? field.computeTargetInterval(targetValue) : null;
      
      return widgetBuilder(
        displayField: field,
        param: param!,
        color: color,
        targetInterval: targetInterval,
      );
    }
    return Text('${field.label}: (unknown display type)', style: const TextStyle(color: Colors.red));
  }

  Color? _getFieldColor(dynamic value, num factor, Color? color) {
    if (target != null && param != null) {
      final targetValue = target is num ? target : num.tryParse(target.toString());
      if (param!.isWithinTarget(targetValue, field.targetRange)) {
        color = Colors.green[700];
      } else {
        color = Colors.red[700];
      }
    }
    return color;
  }
}
