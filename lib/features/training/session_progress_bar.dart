import 'package:flutter/material.dart';

class SessionProgressBar extends StatelessWidget {
  final double progress;
  final int timeLeft;
  final String Function(int) formatTime;
  const SessionProgressBar({
    super.key,
    required this.progress,
    required this.timeLeft,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
