// This file was moved from lib/training_session_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TrainingSession {
  final String title;
  final String ftmsMachineType;
  final List<UnitTrainingInterval> intervals;

  TrainingSession({required this.title, required this.ftmsMachineType, required this.intervals});

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final List intervalsRaw = json['intervals'] as List;
    final List<UnitTrainingInterval> expandedIntervals = [];
    for (final e in intervalsRaw) {
      final interval = TrainingIntervalFactory.fromJsonPolymorphic(e);
      expandedIntervals.addAll(interval.expand());
    }
    return TrainingSession(
      title: json['title'],
      ftmsMachineType: json['ftmsMachineType'],
      intervals: expandedIntervals,
    );
  }
}


/// Abstract base for intervals (first-level: can be group or unit)
abstract class TrainingInterval {
  int? get repeat;
  List<UnitTrainingInterval> expand();
}

/// Leaf interval (unit, can be at top level or inside a group)
class UnitTrainingInterval extends TrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;
  @override
  final int? repeat;

  UnitTrainingInterval({this.title, required this.duration, this.targets, this.resistanceLevel, this.repeat});

  factory UnitTrainingInterval.fromJson(Map<String, dynamic> json) {
    return UnitTrainingInterval(
      title: json['title'],
      duration: json['duration'],
      targets: json['targets'] != null ? Map<String, dynamic>.from(json['targets']) : null,
      resistanceLevel: json['resistanceLevel'],
      repeat: json['repeat'],
    );
  }

  @override
  List<UnitTrainingInterval> expand() {
    final r = repeat ?? 1;
    return List.generate(r > 0 ? r : 1, (_) => this);
  }
}

/// Group interval (first-level only, contains only UnitTrainingInterval children)
class GroupTrainingInterval extends TrainingInterval {
  @override
  final int? repeat;
  final List<UnitTrainingInterval> intervals;

  GroupTrainingInterval({required this.intervals, this.repeat});

  factory GroupTrainingInterval.fromJson(Map<String, dynamic> json) {
    return GroupTrainingInterval(
      repeat: json['repeat'],
      intervals: (json['intervals'] as List)
          .map((e) => UnitTrainingInterval.fromJson(e))
          .toList(),
    );
  }

  @override
  List<UnitTrainingInterval> expand() {
    final r = repeat ?? 1;
    final flat = <UnitTrainingInterval>[];
    for (int i = 0; i < (r > 0 ? r : 1); i++) {
      for (final interval in intervals) {
        flat.addAll(interval.expand());
      }
    }
    return flat;
  }
}

extension TrainingIntervalFactory on TrainingInterval {
  /// Only first-level can be group, second-level must be unit
  static TrainingInterval fromJsonPolymorphic(Map<String, dynamic> json) {
    if (json.containsKey('intervals')) {
      return GroupTrainingInterval.fromJson(json);
    } else {
      return UnitTrainingInterval.fromJson(json);
    }
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

