import 'package:flutter/material.dart';
import '../../core/utils/ftms_display_config.dart';
import '../../core/utils/ftms_icon_registry.dart';

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
      children.add(Row(
        children: [
          if (field.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(getFtmsIcon(field.icon), size: 18),
            ),
          Text('${field.label}: ', style: labelStyle ?? const TextStyle(fontWeight: FontWeight.w500)),
          Text('${entry.value}', style: valueStyle),
          if (field.unit.isNotEmpty) Text(' ${field.unit}', style: valueStyle),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
