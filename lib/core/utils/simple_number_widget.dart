import 'package:flutter/material.dart';
import 'ftms_icon_registry.dart';

/// Widget for displaying a value as a simple number with label.
class SimpleNumberWidget extends StatelessWidget {
  final String label;
  final num value;
  final String unit;
  final String? icon;
  final Color? color;
  const SimpleNumberWidget({Key? key, required this.label, required this.value, required this.unit, this.icon, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData? iconData = getFtmsIcon(icon);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$value $unit', style: TextStyle(fontSize: 22, color: color)),
        if (iconData != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(iconData, size: 20, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
