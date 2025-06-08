import 'package:flutter/material.dart';
import 'package:ftms/core/models/ftms_display_field.dart';

import '../models/ftms_parameter.dart';
import 'ftms_icon_registry.dart';

/// Widget for displaying a value as a simple number with label.
class SimpleNumberWidget extends StatelessWidget {
  final FtmsDisplayField displayField;
  final Color? color;
  final FtmsParameter param;
  const SimpleNumberWidget(this.displayField, this.param, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    IconData? iconData = getFtmsIcon(displayField.icon);
    final scaledValue = param.getScaledValue();
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
