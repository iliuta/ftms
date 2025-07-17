import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// Model representing a FIT file with metadata
class FitFileInfo {
  final String fileName;
  final String filePath;
  final DateTime creationDate;
  final int fileSizeBytes;

  FitFileInfo({
    required this.fileName,
    required this.filePath,
    required this.creationDate,
    required this.fileSizeBytes,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes}B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}

/// Service for managing FIT files - listing, deleting, and checking sync status
class FitFileManager {
  static const String _fitFilesDirName = 'fit_files';

  /// Get the FIT files directory
  Future<Directory> _getFitFilesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/$_fitFilesDirName');
  }

  /// Get all FIT files sorted by creation date (newest first)
  Future<List<FitFileInfo>> getAllFitFiles() async {
    try {
      final fitDir = await _getFitFilesDirectory();
      
      if (!await fitDir.exists()) {
        logger.i('FIT files directory does not exist');
        return [];
      }

      final files = await fitDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.fit'))
          .cast<File>()
          .toList();

      final fitFiles = <FitFileInfo>[];

      for (final file in files) {
        try {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;
          
          fitFiles.add(FitFileInfo(
            fileName: fileName,
            filePath: file.path,
            creationDate: stat.modified,
            fileSizeBytes: stat.size,
          ));
        } catch (e) {
          logger.w('Failed to get stats for file ${file.path}: $e');
        }
      }

      // Sort by creation date (newest first)
      fitFiles.sort((a, b) => b.creationDate.compareTo(a.creationDate));

      logger.i('Found ${fitFiles.length} FIT files');
      return fitFiles;
    } catch (e) {
      logger.e('Failed to list FIT files: $e');
      return [];
    }
  }

  /// Delete a specific FIT file
  Future<bool> deleteFitFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('Successfully deleted FIT file: $filePath');
        return true;
      } else {
        logger.w('FIT file not found: $filePath');
        return false;
      }
    } catch (e) {
      logger.e('Failed to delete FIT file $filePath: $e');
      return false;
    }
  }

  /// Delete multiple FIT files
  Future<List<String>> deleteFitFiles(List<String> filePaths) async {
    final failedDeletions = <String>[];
    
    for (final filePath in filePaths) {
      final success = await deleteFitFile(filePath);
      if (!success) {
        failedDeletions.add(filePath);
      }
    }
    
    return failedDeletions;
  }

  /// Get the total number of FIT files
  Future<int> getFitFileCount() async {
    final files = await getAllFitFiles();
    return files.length;
  }

  /// Get the total size of all FIT files in bytes
  Future<int> getTotalFitFileSize() async {
    final files = await getAllFitFiles();
    int totalSize = 0;
    for (final file in files) {
      totalSize += file.fileSizeBytes;
    }
    return totalSize;
  }
}
