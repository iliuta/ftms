// This file was moved from lib/training_session_expansion_panel.dart
import 'package:flutter/material.dart';
import 'training_session_loader.dart';

class TrainingSessionExpansionPanelList extends StatefulWidget {
  final List<TrainingSession> sessions;
  final ScrollController scrollController;
  const TrainingSessionExpansionPanelList({Key? key, required this.sessions, required this.scrollController}) : super(key: key);

  @override
  State<TrainingSessionExpansionPanelList> createState() => _TrainingSessionExpansionPanelListState();
}

class _TrainingSessionExpansionPanelListState extends State<TrainingSessionExpansionPanelList> {
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List<bool>.filled(widget.sessions.length, false);
  }

  @override
  void didUpdateWidget(covariant TrainingSessionExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions.length != widget.sessions.length) {
      _expanded = List<bool>.filled(widget.sessions.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _expanded[index] = !_expanded[index];
          });
        },
        children: List.generate(widget.sessions.length, (idx) {
          final session = widget.sessions[idx];
          return ExpansionPanel(
            headerBuilder: (context, isExpanded) => ListTile(
              title: Text(session.title),
              subtitle: Text('Intervals: ${session.intervals.length}'),
              trailing: isExpanded ? const Icon(Icons.expand_less) : const Icon(Icons.expand_more),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...session.intervals.map((interval) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${interval.title ?? 'Interval'}: ${interval.duration}s'
                          '${interval.targets != null ? '\nTargets: ${interval.targets}' : ''}',
                        ),
                      )),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start This Session'),
                      onPressed: () async {
                        // Pop and return the selected session
                        Navigator.pop(context, session);
                      },
                    ),
                  ),
                ],
              ),
            ),
            isExpanded: _expanded[idx],
            canTapOnHeader: true,
          );
        }),
      ),
    );
  }
}

