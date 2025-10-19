import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/chart_session.dart';
import '../services/logger_service.dart'; // Add this import

class ChartSessionService {
  static const String _chartsFolder = 'charts';

  /// Get the directory where chart sessions are stored
  Future<Directory> _getChartsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final chartsDir = Directory('${appDir.path}/$_chartsFolder');
    if (!await chartsDir.exists()) {
      await chartsDir.create(recursive: true);
    }
    return chartsDir;
  }

  /// Save a chart session to a JSON file
  Future<String> saveChartSession(ChartSession session) async {
    try {
      final chartsDir = await _getChartsDirectory();
      final fileName = '${session.chartId}.json';
      final file = File('${chartsDir.path}/$fileName');

      // Save the chart session data to a JSON file
      await file.writeAsString(jsonEncode(session.toJson()));

      return fileName;
    } catch (e) {
      AppLogger.error('Error saving chart session: $e');
      rethrow;
    }
  }

  /// Load a chart session from a JSON file
  Future<ChartSession?> loadChartSession(String chartId) async {
    try {
      final chartsDir = await _getChartsDirectory();
      final fileName = '$chartId.json';
      final file = File('${chartsDir.path}/$fileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return ChartSession.fromJson(json);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error loading chart session: $e');
      return null;
    }
  }

  /// Load all chart sessions
  Future<List<ChartSession>> loadAllChartSessions() async {
    try {
      final chartsDir = await _getChartsDirectory();
      final List<ChartSession> sessions = [];

      // List all JSON files in the charts directory
      final files = chartsDir.listSync().where((file) {
        return file.path.endsWith('.json');
      });

      // Load each chart session file
      for (final file in files) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content);
          final session = ChartSession.fromJson(json);
          sessions.add(session);
        } catch (e) {
          AppLogger.error('Error loading chart session file ${file.path}: $e');
        }
      }

      return sessions;
    } catch (e) {
      AppLogger.error('Error loading chart sessions: $e');
      return [];
    }
  }

  /// Delete a chart session
  Future<void> deleteChartSession(String chartId) async {
    try {
      final chartsDir = await _getChartsDirectory();
      final fileName = '$chartId.json';
      final file = File('${chartsDir.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.error('Error deleting chart session: $e');
    }
  }

  /// Clear all chart sessions
  Future<void> clearAllChartSessions() async {
    try {
      final chartsDir = await _getChartsDirectory();
      if (await chartsDir.exists()) {
        // Instead of deleting the entire directory, delete individual files
        final files = chartsDir.listSync();
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
      AppLogger.error('Error clearing chart sessions: $e');
    }
  }
}
