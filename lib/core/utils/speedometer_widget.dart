import 'package:flutter/material.dart';

/// Widget for displaying a value as a speedometer (gauge).
class SpeedometerWidget extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color color;
  const SpeedometerWidget({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    // Simple arc representation (not a real gauge, for demo)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 100,
          height: 60,
          child: CustomPaint(
            painter: _GaugePainter(value, min, max, color),
          ),
        ),
        Text('${value.toStringAsFixed(0)} $unit', style: TextStyle(fontSize: 18, color: color)),
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
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final sweep = ((value - min) / (max - min)).clamp(0, 1) * 3.14;
    canvas.drawArc(rect, 3.14, sweep, false, paintValue);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
