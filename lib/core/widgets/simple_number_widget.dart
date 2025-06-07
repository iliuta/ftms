import 'package:flutter/material.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import 'ftms_icon_registry.dart';

/// Widget for displaying a value as a simple number with label.
class SimpleNumberWidget extends StatelessWidget {
  final FtmsDisplayField displayField;
  final Color? color;
  final dynamic param;
  const SimpleNumberWidget(this.displayField, this.param, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    IconData? iconData = getFtmsIcon(displayField.icon);
    final value = param.value ?? param.toString();
    final factor = (param.factor is num)
        ? param.factor as num
        : num.tryParse(param.factor?.toString() ?? '1') ?? 1;
    final scaledValue = displayField.getScaledValue(value, factor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(displayField.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$scaledValue ${displayField.unit}', style: TextStyle(fontSize: 22, color: color)),
        if (iconData != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(iconData, size: 20, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
