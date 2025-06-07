import 'package:flutter/material.dart';
import 'package:ftms/core/config/field_format_strategy.dart';
import 'package:ftms/core/config/ftms_display_config.dart';

/// Widget for displaying a value as a speedometer (gauge).
class SpeedometerWidget extends StatelessWidget {
  final FtmsDisplayField displayField;
  final dynamic param;
  final Color color;

  const SpeedometerWidget(
      {super.key,
      required this.displayField,
      this.param,
      this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    double? min =
        (displayField.min is num) ? (displayField.min as num).toDouble() : null;
    double? max =
        (displayField.max is num) ? (displayField.max as num).toDouble() : null;
    final value = param.value ?? param.toString();
    final factor = (param.factor is num)
        ? param.factor as num
        : num.tryParse(param.factor?.toString() ?? '1') ?? 1;
    final scaledValue = displayField.getScaledValue(value, factor);
    // if there is a formatter, then use the field format strategy to init a variable
    // with the formatted value
    String formattedValue = '${scaledValue.toStringAsFixed(0)} ${displayField.unit}';
    if (displayField.formatter != null) {
      final formatterStrategy =
          FieldFormatter.getStrategy(displayField.formatter!);
      if (formatterStrategy != null) {
        formattedValue = formatterStrategy.format(
            field: displayField, paramValue: scaledValue);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(displayField.label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 100,
          height: 60,
          child: CustomPaint(
            painter: _GaugePainter(scaledValue.toDouble(), min!, max!, color),
          ),
        ),
        Text(formattedValue, style: TextStyle(fontSize: 18, color: color)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;

  _GaugePainter(this.value, this.min, this.max, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Draw background arc
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
    // Draw value arc
    final paintValue = Paint()
      ..color = color // Utilise la couleur passée au constructeur
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final sweep = ((value - min) / (max - min)).clamp(0, 1) * 3.14;
    canvas.drawArc(rect, 3.14, sweep, false, paintValue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
