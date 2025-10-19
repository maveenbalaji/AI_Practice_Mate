import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user_progress.dart';
import '../services/logger_service.dart'; // Add this import

class ProgressService {
  static const String _historyFolder = 'user_history';
  static const String _indexFileName = 'history_index.json';

  /// Get the directory where user history is stored
  Future<Directory> _getHistoryDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${appDir.path}/$_historyFolder');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  /// Save user progress to a JSON file
  Future<String> saveUserProgress(UserProgress progress) async {
    try {
      final historyDir = await _getHistoryDirectory();
      final fileName = '${progress.chartId}.json';
      final file = File('${historyDir.path}/$fileName');

      // Save the progress data to a JSON file
      await file.writeAsString(jsonEncode(progress.toJson()));

      // Update the index file
      await _updateIndexFile(progress);

      return fileName;
    } catch (e) {
      AppLogger.error('Error saving user progress: $e');
      rethrow;
    }
  }

  /// Update the history index file with the new progress entry
  Future<void> _updateIndexFile(UserProgress progress) async {
    try {
      final historyDir = await _getHistoryDirectory();
      final indexFile = File('${historyDir.path}/$_indexFileName');

      // Read existing index data
      List<Map<String, dynamic>> indexData = [];
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            indexData = List<Map<String, dynamic>>.from(decoded);
          }
        }
      }

      // Add the new entry
      indexData.add({
        'chart_id': progress.chartId,
        'title': progress.title,
        'timestamp': progress.timestamp,
        'score': progress.score,
        'correct': progress.correct,
        'difficulty': progress.difficulty,
      });

      // Save the updated index
      await indexFile.writeAsString(jsonEncode(indexData));
    } catch (e) {
      AppLogger.error('Error updating index file: $e');
    }
  }

  /// Load all user progress entries from JSON files
  Future<List<UserProgress>> loadAllUserProgress() async {
    try {
      final historyDir = await _getHistoryDirectory();
      final List<UserProgress> progressList = [];

      // List all JSON files in the history directory
      final files = historyDir.listSync().where((file) {
        return file.path.endsWith('.json') &&
            !file.path.endsWith(_indexFileName);
      });

      // Load each progress file
      for (final file in files) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content);
          final progress = UserProgress.fromJson(json);
          progressList.add(progress);
        } catch (e) {
          AppLogger.error('Error loading progress file ${file.path}: $e');
        }
      }

      return progressList;
    } catch (e) {
      AppLogger.error('Error loading user progress: $e');
      return [];
    }
  }

  /// Load progress index (summary data for quick access)
  Future<List<Map<String, dynamic>>> loadProgressIndex() async {
    try {
      final historyDir = await _getHistoryDirectory();
      final indexFile = File('${historyDir.path}/$_indexFileName');

      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            return List<Map<String, dynamic>>.from(decoded);
          }
        }
      }

      return [];
    } catch (e) {
      AppLogger.error('Error loading progress index: $e');
      return [];
    }
  }

  /// Clear all user progress data
  Future<void> clearAllProgress() async {
    try {
      final historyDir = await _getHistoryDirectory();
      if (await historyDir.exists()) {
        // Instead of deleting the entire directory, delete individual files
        final files = historyDir.listSync();
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            AppLogger.error('Error deleting file ${file.path}: $e');
            // Continue with other files even if one fails
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error clearing progress data: $e');
    }
  }

  /// Export all progress data as a zip file
  Future<String?> exportProgressData() async {
    try {
      // This would require additional implementation with the archive package
      // For now, we'll just return null to indicate the feature is not implemented
      return null;
    } catch (e) {
      AppLogger.error('Error exporting progress data: $e');
      return null;
    }
  }
}
