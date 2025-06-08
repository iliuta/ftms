import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ftms/core/config/field_format_strategy.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import '../models/ftms_parameter.dart';

/// Widget for displaying a value as a speedometer (gauge).
class SpeedometerWidget extends StatelessWidget {
  final FtmsDisplayField displayField;
  final FtmsParameter? param;
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
    
    if (param == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayField.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('No data', style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    
    final value = param!.value;
    final factor = param!.factor;
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
          width: 140,
          height: 80,
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
    // Use the smaller dimension to ensure a perfect circle
    final diameter = math.min(size.width, size.height);
    final radius = diameter / 2;
    
    // Center the circle in the available space
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    // Create a square rect centered in the available space for a perfect circle
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: diameter,
      height: diameter,
    );
    
    // Draw background arc
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
    // Draw value arc
    final paintValue = Paint()
      ..color = color // Utilise la couleur passée au constructeur
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final sweep = ((value - min) / (max - min)).clamp(0, 1) * 3.14;
    canvas.drawArc(rect, 3.14, sweep, false, paintValue);
    
    // Draw hour hand (needle)
    final center = Offset(centerX, centerY);
    final angle = 3.14 + ((value - min) / (max - min)).clamp(0, 1) * 3.14;
    final needleLength = radius * 0.7; // 70% of the radius
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );
    
    final needlePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw the needle line
    canvas.drawLine(center, needleEnd, needlePaint);
    
    // Draw center dot
    final centerDotPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
