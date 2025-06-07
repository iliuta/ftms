// This file was moved from lib/training_session_loader.dart
import 'dart:convert';
import '../../core/utils/logger.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'model/training_session.dart';



Future<List<TrainingSessionDefinition>> loadTrainingSessions(String machineType) async {
  logger.i('[loadTrainingSessions] machineType: $machineType');
  // Use AssetManifest to list all training session files
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);
  final sessionFiles = manifestMap.keys
      .where((String key) => key.startsWith('lib/training-sessions/') && key.endsWith('.json'))
      .toList();
  logger.i('[loadTrainingSessions] Found files:');
  for (final f in sessionFiles) {
    logger.i('  - $f');
  }
  List<TrainingSessionDefinition> sessions = [];
  for (final file in sessionFiles) {
    try {
      final content = await rootBundle.loadString(file);
      final jsonData = json.decode(content);
      final session = TrainingSessionDefinition.fromJson(jsonData);
      logger.i('[loadTrainingSessions] Read session: title=${session.title}, ftmsMachineType=${session.ftmsMachineType}');
      if (session.ftmsMachineType == machineType) {
        logger.i('[loadTrainingSessions]   -> MATCH');
        sessions.add(session);
      } else {
        logger.i('[loadTrainingSessions]   -> SKIP');
      }
    } catch (e) {
      logger.e('[loadTrainingSessions] Error reading $file: $e');
    }
  }
  logger.i('[loadTrainingSessions] Returning ${sessions.length} sessions');
  return sessions;
}

