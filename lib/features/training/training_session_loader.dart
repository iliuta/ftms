// This file was moved from lib/training_session_loader.dart
import 'dart:convert';
import 'package:ftms/core/models/device_types.dart';

import '../../core/utils/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/services/training_session_storage_service.dart';
import '../../core/config/live_data_display_config.dart';

import 'model/training_session.dart';
import '../settings/model/user_settings.dart';



Future<List<TrainingSessionDefinition>> loadTrainingSessions(DeviceType machineType) async {
  logger.i('[loadTrainingSessions] machineType: $machineType');
  final userSettings = await UserSettings.loadDefault();
  final config = await LiveDataDisplayConfig.loadForFtmsMachineType(machineType);
  final List<TrainingSessionDefinition> sessions = [];
  
  // Load built-in sessions from assets
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);
  final sessionFiles = manifestMap.keys
      .where((String key) => key.startsWith('lib/training-sessions/') && key.endsWith('.json'))
      .toList();
  logger.i('[loadTrainingSessions] Found built-in files:');
  for (final f in sessionFiles) {
    logger.i('  - $f');
  }
  
  // Load built-in sessions
  for (final file in sessionFiles) {
    try {
      final content = await rootBundle.loadString(file);
      final jsonData = json.decode(content);
      final session = TrainingSessionDefinition.fromJson(jsonData, isCustom: false)
          .expand(userSettings: userSettings, config: config);
      logger.i('[loadTrainingSessions] Read built-in session: title=${session.title}, ftmsMachineType=${session.ftmsMachineType}');
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
  
  // Load custom sessions
  try {
    final storageService = TrainingSessionStorageService();
    final customSessions = await storageService.loadCustomSessions();
    logger.i('[loadTrainingSessions] Found ${customSessions.length} custom sessions');
    
    for (final session in customSessions) {
      final expandedSession = session.expand(userSettings: userSettings, config: config);
      logger.i('[loadTrainingSessions] Read custom session: title=${expandedSession.title}, ftmsMachineType=${expandedSession.ftmsMachineType}');
      if (expandedSession.ftmsMachineType == machineType) {
        logger.i('[loadTrainingSessions]   -> MATCH');
        sessions.add(expandedSession);
      } else {
        logger.i('[loadTrainingSessions]   -> SKIP');
      }
    }
  } catch (e) {
    logger.e('[loadTrainingSessions] Error loading custom sessions: $e');
  }
  
  logger.i('[loadTrainingSessions] Returning ${sessions.length} total sessions');
  return sessions;
}

