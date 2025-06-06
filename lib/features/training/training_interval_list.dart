import 'package:flutter/material.dart';
import 'training_session_loader.dart';

class TrainingIntervalList extends StatelessWidget {
  final List<TrainingInterval> intervals;
  final int currentInterval;
  final int intervalElapsed;
  final int intervalTimeLeft;
  final String Function(int) formatMMSS;

  const TrainingIntervalList({
    Key? key,
    required this.intervals,
    required this.currentInterval,
    required this.intervalElapsed,
    required this.intervalTimeLeft,
    required this.formatMMSS,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remainingIntervals = intervals.sublist(currentInterval);
    return ListView.builder(
      itemCount: remainingIntervals.length,
      itemBuilder: (context, idx) {
        final interval = remainingIntervals[idx];
        final isCurrent = idx == 0;
        final intervalProgress = isCurrent ? intervalElapsed / interval.duration : 0.0;
        return Card(
          color: isCurrent ? Colors.blue[50] : null,
          child: ListTile(
            title: Text(interval.title ?? 'Interval'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: intervalProgress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Text(
                        formatMMSS(intervalTimeLeft),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    else
                      Text('${interval.duration}s'),
                  ],
                ),
                if (interval.targets != null)
                  Text('Targets: ${interval.targets}')
              ],
            ),
          ),
        );
      },
    );
  }
}
