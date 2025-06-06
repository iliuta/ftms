// This file was moved from lib/training_session_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'model/training_interval.dart';
import 'model/group_training_interval.dart';
import 'model/unit_training_interval.dart';
import 'model/training_session.dart';


Future<List<TrainingSessionDefinition>> loadTrainingSessions(String machineType) async {
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
  List<TrainingSessionDefinition> sessions = [];
  for (final file in sessionFiles) {
    try {
      final content = await rootBundle.loadString(file);
      final jsonData = json.decode(content);
      final session = TrainingSessionDefinition.fromJson(jsonData);
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

