import 'package:flutter/material.dart';
import '../config/ftms_display_config.dart';
import 'ftms_field_display.dart';

/// Shared widget for displaying FTMS live data fields according to config.
class FtmsLiveDataDisplayWidget extends StatelessWidget {
  final FtmsDisplayConfig config;
  final Map<String, dynamic> paramValueMap;
  final Map<String, dynamic>? targets;
  final bool Function(num? value, num? target, {num factor})? isWithinTarget;
  final Color? defaultColor;
  final String? machineType;
  const FtmsLiveDataDisplayWidget({
    super.key,
    required this.config,
    required this.paramValueMap,
    this.targets,
    this.isWithinTarget,
    this.defaultColor,
    this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = _calculateColumnCount(constraints.maxWidth, config.fields.length);
        final rows = _buildRows(columns);
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

  int _calculateColumnCount(double maxWidth, int fieldCount) {
    const double columnWidth = 180;
    return (maxWidth / columnWidth).floor().clamp(1, fieldCount);
  }

  List<List<Widget>> _buildRows(int columns) {
    final List<List<Widget>> rows = [];
    List<Widget> currentRow = [];
    for (int i = 0; i < config.fields.length; i++) {
      currentRow.add(_buildFieldWidget(config.fields[i]));
      if ((currentRow.length == columns) || (i == config.fields.length - 1)) {
        rows.add(currentRow);
        currentRow = [];
      }
    }
    return rows;
  }

  Widget _buildFieldWidget(FtmsDisplayField field) {
    final param = paramValueMap[field.name];
    final target = targets != null ? targets![field.name] : null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: FtmsFieldDisplay(
          field: field,
          param: param,
          target: target,
          isWithinTarget: isWithinTarget,
          defaultColor: defaultColor,
          machineType: machineType,
        ),
      ),
    );
  }
}
