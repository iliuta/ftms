// This file was moved from lib/training_session_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TrainingSession {
  final String title;
  final String ftmsMachineType;
  final List<TrainingInterval> intervals;

  TrainingSession({required this.title, required this.ftmsMachineType, required this.intervals});

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      title: json['title'],
      ftmsMachineType: json['ftmsMachineType'],
      intervals: (json['intervals'] as List)
          .map((e) => TrainingInterval.fromJson(e))
          .toList(),
    );
  }
}

class TrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;

  TrainingInterval({this.title, required this.duration, this.targets, this.resistanceLevel});

  factory TrainingInterval.fromJson(Map<String, dynamic> json) {
    return TrainingInterval(
      title: json['title'],
      duration: json['duration'],
      targets: json['targets'] != null ? Map<String, dynamic>.from(json['targets']) : null,
      resistanceLevel: json['resistanceLevel'],
    );
  }
}

Future<List<TrainingSession>> loadTrainingSessions(String machineType) async {
  // ignore: avoid_print
  print('[loadTrainingSessions] machineType: $machineType');
  // Use AssetManifest to list all training session files
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);
  final sessionFiles = manifestMap.keys
      .where((String key) => key.startsWith('lib/training-sessions/') && key.endsWith('.json'))
      .toList();
  print('[loadTrainingSessions] Found files:');
  for (final f in sessionFiles) {
    print('  - $f');
  }
  List<TrainingSession> sessions = [];
  for (final file in sessionFiles) {
    try {
      final content = await rootBundle.loadString(file);
      final jsonData = json.decode(content);
      final session = TrainingSession.fromJson(jsonData);
      print('[loadTrainingSessions] Read session: title=${session.title}, ftmsMachineType=${session.ftmsMachineType}');
      if (session.ftmsMachineType == machineType) {
        print('[loadTrainingSessions]   -> MATCH');
        sessions.add(session);
      } else {
        print('[loadTrainingSessions]   -> SKIP');
      }
    } catch (e) {
      print('[loadTrainingSessions] Error reading $file: $e');
    }
  }
  print('[loadTrainingSessions] Returning ${sessions.length} sessions');
  return sessions;
}

