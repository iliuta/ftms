import 'package:flutter/material.dart';
import 'package:ftms/core/models/ftms_display_field.dart';

import '../../core/config/ftms_display_config.dart';
import '../../core/config/field_format_strategy.dart';
import '../../core/widgets/ftms_icon_registry.dart';

class IntervalTargetFieldsDisplay extends StatelessWidget {
  final Map<String, dynamic>? targets;
  final FtmsDisplayConfig? config;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const IntervalTargetFieldsDisplay({
    super.key,
    required this.targets,
    required this.config,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (targets == null || targets!.isEmpty) return const SizedBox.shrink();
    if (config == null) {
      // fallback: show raw
      return Text('Targets: $targets');
    }
    final List<Widget> children = [];
    for (final entry in targets!.entries) {
      final field = config!.fields.firstWhere(
        (f) => f.name == entry.key,
        orElse: () => FtmsDisplayField(
          name: entry.key,
          label: entry.key,
          display: 'number',
          unit: '',
        ),
      );
      
      // Format the value using the field's formatter if available
      String formattedValue = '${entry.value}${field.unit.isNotEmpty ? ' ${field.unit}' : ''}';
      if (field.formatter != null) {
        final formatterStrategy = FieldFormatter.getStrategy(field.formatter!);
        if (formatterStrategy != null) {
          formattedValue = formatterStrategy.format(
            field: field, 
            paramValue: entry.value
          );
        }
      }
      
      children.add(Row(
        children: [
          if (field.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(getFtmsIcon(field.icon), size: 16),
            ),
          Flexible(
            child: Text(
              '${field.label}: ', 
              style: labelStyle ?? const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              formattedValue, 
              style: valueStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
