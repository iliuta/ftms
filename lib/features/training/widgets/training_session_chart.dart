import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/features/training/model/expanded_unit_training_interval.dart';

import '../../../core/config/live_data_display_config.dart';
import '../interval_target_fields_display.dart';

/// A visual chart showing training session intensity over time with interactive hover
class TrainingSessionChart extends StatefulWidget {
  final List<ExpandedUnitTrainingInterval> intervals;
  final DeviceType machineType;
  final double height;
  final LiveDataDisplayConfig? config;

  const TrainingSessionChart({
    super.key,
    required this.intervals,
    required this.machineType,
    this.height = 120,
    this.config,
  });

  @override
  State<TrainingSessionChart> createState() => _TrainingSessionChartState();
}

class _TrainingSessionChartState extends State<TrainingSessionChart> {
  int? _hoveredIntervalIndex;
  Offset? _hoverPosition;
  Timer? _clearHoverTimer;

  @override
  Widget build(BuildContext context) {
    if (widget.intervals.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('No intervals'),
        ),
      );
    }

    final totalDuration = widget.intervals.fold<int>(0, (sum, interval) => sum + interval.duration);
    final intensityKey = _getIntensityKey();

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onPanUpdate: (details) => _handleHover(details.localPosition),
                        onTapDown: (details) => _handleHover(details.localPosition),
                        onTapUp: (_) => _clearHover(),
                        onPanEnd: (_) => _clearHover(),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _TrainingChartPainter(
                            intervals: widget.intervals,
                            totalDuration: totalDuration,
                            intensityKey: intensityKey,
                            machineType: widget.machineType,
                            hoveredIndex: _hoveredIntervalIndex,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTimeAxisLabels(totalDuration),
                  ],
                ),
              ),
              // Hover tooltip - now outside the padded container
              if (_hoveredIntervalIndex != null && _hoverPosition != null)
                _buildHoverTooltip(constraints.biggest),
            ],
          );
        },
      ),
    );
  }

  void _handleHover(Offset position) {
    // Cancel any pending clear hover timer
    _clearHoverTimer?.cancel();
    
    final totalDuration = widget.intervals.fold<int>(0, (sum, interval) => sum + interval.duration);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final chartSize = renderBox.size;
    final paddedWidth = chartSize.width - 16; // Account for padding
    
    if (paddedWidth <= 0) return;
    
    // Calculate which interval the touch/hover is over
    double currentX = 8; // Account for left padding
    int? hoveredIndex;
    
    for (int i = 0; i < widget.intervals.length; i++) {
      final interval = widget.intervals[i];
      final barWidth = (interval.duration / totalDuration) * paddedWidth;
      
      if (position.dx >= currentX && position.dx <= currentX + barWidth) {
        hoveredIndex = i;
        break;
      }
      currentX += barWidth;
    }
    
    setState(() {
      _hoveredIntervalIndex = hoveredIndex;
      _hoverPosition = hoveredIndex != null ? position : null;
    });
  }

  void _clearHover() {
    // Add a small delay to prevent flickering
    _clearHoverTimer?.cancel();
    _clearHoverTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _hoveredIntervalIndex = null;
          _hoverPosition = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _clearHoverTimer?.cancel();
    super.dispose();
  }

  Widget _buildHoverTooltip(Size containerSize) {
    if (_hoveredIntervalIndex == null || _hoverPosition == null) {
      return const SizedBox.shrink();
    }
    
    final interval = widget.intervals[_hoveredIntervalIndex!];
    final position = _hoverPosition!;
    
    // Calculate smart positioning to avoid truncation
    const tooltipWidth = 200.0;
    const tooltipHeight = 100.0; // Increased height to accommodate more content
    const padding = 0.0; // Increased padding now that tooltip is outside container
    
    // Calculate horizontal position - adjust for the 8px padding
    double left = position.dx + 8; // Add 8px to account for container padding
    if (left + tooltipWidth > containerSize.width - padding) {
      // Position to the left of the touch point if it would overflow
      left = (position.dx + 8) - tooltipWidth - 10; // Add 8px to account for container padding
    }
    // Ensure it doesn't go off the left edge
    if (left < padding) {
      left = padding;
    }
    
  
    double top = (containerSize.height - tooltipHeight) / 2 - 10; // Center vertically with a slight offset

    
    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: tooltipWidth),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                interval.title ?? 'Interval ${_hoveredIntervalIndex! + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Duration: ${_formatDuration(interval.duration)}',
                style: const TextStyle(fontSize: 12),
              ),
              if (interval.targets != null && interval.targets!.isNotEmpty) ...[
                const SizedBox(height: 8),
                IntervalTargetFieldsDisplay(
                  targets: interval.targets,
                  config: widget.config,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getIntensityKey() {
    switch (widget.machineType) {
      case DeviceType.rower:
        return 'Instantaneous Pace';
      case DeviceType.indoorBike:
        return 'Instantaneous Power';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  Widget _buildTimeAxisLabels(int totalDuration) {
    final labels = <Widget>[];
    final numLabels = 5; // Show 5 time labels
    
    for (int i = 0; i <= numLabels; i++) {
      final timeSeconds = (totalDuration * i / numLabels).round();
      final timeText = _formatTime(timeSeconds);
      labels.add(Expanded(
        child: Text(
          timeText,
          textAlign: i == 0 ? TextAlign.start : 
                   i == numLabels ? TextAlign.end : TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ));
    }
    
    return Row(children: labels);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _TrainingChartPainter extends CustomPainter {
  final List<ExpandedUnitTrainingInterval> intervals;
  final int totalDuration;
  final String intensityKey;
  final int? hoveredIndex;
  final DeviceType machineType;

  _TrainingChartPainter({
    required this.intervals,
    required this.totalDuration,
    required this.intensityKey,
    required this.machineType,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intervals.isEmpty || size.width <= 0 || size.height <= 0) {
      return; // Don't paint if there's nothing to paint or invalid size
    }

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Find min and max intensity values
    final intensities = intervals.map((interval) => _getIntensityValue(interval)).toList();
    if (intensities.isEmpty) return;
    
    final minIntensity = intensities.reduce((a, b) => a < b ? a : b);
    final maxIntensity = intensities.reduce((a, b) => a > b ? a : b);
    
    // Handle case where all values are the same
    final intensityRange = maxIntensity - minIntensity;
    final paddedMin = intensityRange > 0 ? minIntensity - (intensityRange * 0.1) : minIntensity - 10;
    final paddedMax = intensityRange > 0 ? maxIntensity + (intensityRange * 0.1) : maxIntensity + 10;
    final paddedRange = paddedMax - paddedMin;

    double currentX = 0;
    
    for (int i = 0; i < intervals.length; i++) {
      final interval = intervals[i];
      final barWidth = (interval.duration / totalDuration) * size.width;
      final intensity = _getIntensityValue(interval);
      
      // Normalize intensity to chart height (inverted because higher intensity = taller bar)
      final normalizedIntensity = paddedRange > 0 ? (intensity - paddedMin) / paddedRange : 0.5;
      final barHeight = normalizedIntensity * size.height;
      
      // Ensure values are valid numbers
      if (barWidth.isNaN || barHeight.isNaN || !barWidth.isFinite || !barHeight.isFinite) {
        currentX += barWidth.isFinite ? barWidth : 0;
        continue;
      }
      
      // Draw the bar first
      final rect = Rect.fromLTWH(
        currentX,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      
      // Choose color based on intensity and hover state
      if (i == hoveredIndex) {
        // Highlight hovered bar
        paint.color = _getIntensityColor(normalizedIntensity).withValues(alpha: 0.8);
        paint.strokeWidth = 2;
        paint.style = PaintingStyle.fill;
        
        canvas.drawRect(rect, paint);
        
        // Add border to hovered bar
        final borderPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawRect(rect, borderPaint);
      } else {
        paint.color = _getIntensityColor(normalizedIntensity);
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      }
      
      // Draw interval separator (except for the last one)
      if (i < intervals.length - 1) {
        final separatorPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(currentX + barWidth, 0),
          Offset(currentX + barWidth, size.height),
          separatorPaint,
        );
      }
      
      // Draw interval title if there's enough space
      if (barWidth > 30) {
        final textSpan = TextSpan(
          text: interval.title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: barWidth - 4);
        
        if (textPainter.width < barWidth - 4) {
          textPainter.paint(
            canvas,
            Offset(
              currentX + (barWidth - textPainter.width) / 2,
              size.height - barHeight + 4,
            ),
          );
        }
      }
      
      currentX += barWidth;
    }
    
    // Draw baseline
    final baselinePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      baselinePaint,
    );
  }

  double _getIntensityValue(ExpandedUnitTrainingInterval interval) {
    final targets = interval.targets;
    if (targets == null) return 50.0; // Default value if no targets
    final target = targets[intensityKey];
    if (target == null) return 50.0; // Default value
    
    double rawValue;
    if (target is String) {
      // Handle percentage strings like "100%", "95%"
      if (target.endsWith('%')) {
        final percentageStr = target.substring(0, target.length - 1);
        rawValue = double.tryParse(percentageStr) ?? 50.0;
      } else {
        rawValue = double.tryParse(target) ?? 50.0;
      }
    } else if (target is num) {
      rawValue = target.toDouble();
    } else {
      rawValue = 50.0; // Default fallback
    }
    
    // For rowing pace, invert the relationship since higher pace values (slower pace) = lower intensity
    if (machineType == DeviceType.rower && intensityKey == 'Instantaneous Pace') {
      // If it's a percentage, use it directly (100% = baseline intensity)
      if (target is String && target.endsWith('%')) {
        return rawValue; // Percentage values work correctly for intensity
      } else {
        // For absolute pace values, invert them relative to a baseline
        // Assume 120 seconds (2:00/500m) as baseline (100% intensity)
        const baselinePaceSeconds = 120.0;
        return (baselinePaceSeconds * 100) / rawValue; // Invert: slower pace = lower intensity
      }
    }
    
    return rawValue;
  }

  Color _getIntensityColor(double normalizedIntensity) {
    // Clamp the value to [0, 1] to avoid issues
    final clampedIntensity = normalizedIntensity.clamp(0.0, 1.0);
    
    // Create a color gradient from green (low) to red (high)
    if (clampedIntensity < 0.33) {
      // Green to yellow
      return Color.lerp(Colors.green, Colors.yellow, clampedIntensity * 3) ?? Colors.green;
    } else if (clampedIntensity < 0.66) {
      // Yellow to orange
      return Color.lerp(Colors.yellow, Colors.orange, (clampedIntensity - 0.33) * 3) ?? Colors.yellow;
    } else {
      // Orange to red
      return Color.lerp(Colors.orange, Colors.red, (clampedIntensity - 0.66) * 3) ?? Colors.orange;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _TrainingChartPainter ||
           oldDelegate.intervals != intervals ||
           oldDelegate.totalDuration != totalDuration ||
           oldDelegate.intensityKey != intensityKey ||
           oldDelegate.machineType != machineType ||
           oldDelegate.hoveredIndex != hoveredIndex;
  }
}
