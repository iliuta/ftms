import 'package:flutter/material.dart';
import '../config/ftms_display_config.dart';
import 'ftms_display_widget_registry.dart';

/// Shared widget for displaying FTMS live data fields according to config.
class FtmsLiveDataDisplayWidget extends StatelessWidget {
  final FtmsDisplayConfig config;
  final Map<String, dynamic> paramValueMap;
  final Map<String, dynamic>? targets;
  final bool Function(num? value, num? target, {num factor})? isWithinTarget;
  final Color? defaultColor;
  const FtmsLiveDataDisplayWidget({
    super.key,
    required this.config,
    required this.paramValueMap,
    this.targets,
    this.isWithinTarget,
    this.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    // Display fields in order, in columns, with overflow to next line if not enough space
    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate a good width for each column (e.g. 180px)
        const double columnWidth = 180;
        final int columns = (constraints.maxWidth / columnWidth).floor().clamp(1, config.fields.length);
        final List<List<Widget>> rows = [];
        List<Widget> currentRow = [];
        for (int i = 0; i < config.fields.length; i++) {
          final field = config.fields[i];
          final param = paramValueMap[field.name];
          Color? color = defaultColor;
          // FontWeight fontWeight = FontWeight.normal;
          Widget child;
          if (param == null) {
            child = Text('${field.label}: (not available)', style: const TextStyle(color: Colors.grey));
          } else {
            final value = param.value ?? param.toString();
            final factor = (param.factor is num)
                ? param.factor as num
                : num.tryParse(param.factor?.toString() ?? '1') ?? 1;
            final scaledValue = (value is num ? value : num.tryParse(value.toString()) ?? 0) * factor;
            if (targets != null && targets![field.name] != null && isWithinTarget != null) {
              final target = targets![field.name];
              if (isWithinTarget!(value is num ? value : num.tryParse(value.toString()),
                  target is num ? target : num.tryParse(target.toString()), factor: factor)) {
                color = Colors.green[700];
              } else {
                color = Colors.red[700];
              }
            }
            final widgetBuilder = ftmsDisplayWidgetRegistry[field.display];
            if (widgetBuilder != null) {
              child = widgetBuilder(
                label: field.label,
                value: scaledValue,
                unit: field.unit,
                icon: field.icon,
                color: color,
                min: (field.min is num) ? (field.min as num).toDouble() : null,
                max: (field.max is num) ? (field.max as num).toDouble() : null,
              );
            } else {
              child = Text('${field.label}: (unknown display type)', style: const TextStyle(color: Colors.red));
            }
          }
          currentRow.add(Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: child,
          )));
          if ((currentRow.length == columns) || (i == config.fields.length - 1)) {
            rows.add(currentRow);
            currentRow = [];
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows.map((row) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: row,
          )).toList(),
        );
      },
    );
  }
}
