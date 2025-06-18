import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ftms/core/utils/logger.dart';
import '../../features/training/model/training_session.dart';

/// Service for saving and loading user-created training sessions
class TrainingSessionStorageService {
  static const String _customSessionsDir = 'custom_training_sessions';

  /// Get the directory where custom training sessions are stored
  Future<Directory> _getCustomSessionsDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final customSessionsDir = Directory('${documentsDir.path}/$_customSessionsDir');
    
    if (!await customSessionsDir.exists()) {
      await customSessionsDir.create(recursive: true);
    }
    
    return customSessionsDir;
  }

  /// Save a training session to persistent storage
  Future<String> saveSession(TrainingSessionDefinition session) async {
    try {
      final directory = await _getCustomSessionsDirectory();
      
      // Generate a safe filename from the session title
      final safeTitle = _generateSafeFilename(session.title);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${safeTitle}_$timestamp.json';
      final filePath = '${directory.path}/$filename';
      
      // Convert session to JSON
      final sessionJson = session.toJson();
      final jsonString = jsonEncode(sessionJson);
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8);
      
      logger.i('Training session saved successfully: $filePath');
      return filePath;
    } catch (e) {
      logger.e('Failed to save training session: $e');
      throw Exception('Failed to save training session: $e');
    }
  }

  /// Load all custom training sessions
  Future<List<TrainingSessionDefinition>> loadCustomSessions() async {
    try {
      final directory = await _getCustomSessionsDirectory();
      final sessions = <TrainingSessionDefinition>[];
      
      if (!await directory.exists()) {
        return sessions;
      }
      
      final files = directory.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>();
      
      for (final file in files) {
        try {
          final content = await file.readAsString(encoding: utf8);
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          final session = TrainingSessionDefinition.fromJson(jsonData);
          sessions.add(session);
        } catch (e) {
          logger.w('Failed to load session from ${file.path}: $e');
          // Continue loading other sessions even if one fails
        }
      }
      
      logger.i('Loaded ${sessions.length} custom training sessions');
      return sessions;
    } catch (e) {
      logger.e('Failed to load custom training sessions: $e');
      return [];
    }
  }

  /// Delete a custom training session by searching for sessions with matching title and machine type
  Future<bool> deleteSession(String title, String machineType) async {
    try {
      final directory = await _getCustomSessionsDirectory();
      
      if (!await directory.exists()) {
        return false;
      }
      
      final files = directory.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>();
      
      for (final file in files) {
        try {
          final content = await file.readAsString(encoding: utf8);
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          
          if (jsonData['title'] == title && jsonData['ftmsMachineType'] == machineType) {
            await file.delete();
            logger.i('Deleted training session: ${file.path}');
            return true;
          }
        } catch (e) {
          logger.w('Failed to check session in ${file.path}: $e');
        }
      }
      
      logger.w('No matching session found for deletion: $title ($machineType)');
      return false;
    } catch (e) {
      logger.e('Failed to delete training session: $e');
      return false;
    }
  }

  /// Generate a safe filename from a session title
  String _generateSafeFilename(String title) {
    // Replace invalid filename characters with underscores
    final safeTitle = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    
    // Limit length to avoid filesystem issues
    return safeTitle.length > 50 ? safeTitle.substring(0, 50) : safeTitle;
  }

  /// Get the total number of custom training sessions
  Future<int> getCustomSessionCount() async {
    try {
      final directory = await _getCustomSessionsDirectory();
      
      if (!await directory.exists()) {
        return 0;
      }
      
      final files = directory.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .toList();
      
      return files.length;
    } catch (e) {
      logger.e('Failed to get custom session count: $e');
      return 0;
    }
  }

  /// Check if the storage directory is accessible
  Future<bool> isStorageAccessible() async {
    try {
      final directory = await _getCustomSessionsDirectory();
      return await directory.exists();
    } catch (e) {
      logger.e('Storage accessibility check failed: $e');
      return false;
    }
  }
}
