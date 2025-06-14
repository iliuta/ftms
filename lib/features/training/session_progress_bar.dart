import 'package:flutter/material.dart';

class SessionProgressBar extends StatelessWidget {
  final double progress;
  final int timeLeft;
  final int elapsed;
  final String Function(int) formatTime;
  const SessionProgressBar({
    super.key,
    required this.progress,
    required this.timeLeft,
    required this.elapsed,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          formatTime(elapsed),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatTime(timeLeft),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
