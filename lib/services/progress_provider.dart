import 'package:flutter/foundation.dart';
import '../models/user_progress.dart';
import '../services/logger_service.dart'; // Add this import
import 'progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  List<UserProgress> _userProgress = [];
  List<Map<String, dynamic>> _progressIndex = [];
  bool _isLoading = false;

  List<UserProgress> get userProgress => _userProgress;
  List<Map<String, dynamic>> get progressIndex => _progressIndex;
  bool get isLoading => _isLoading;

  /// Load all user progress data
  Future<void> loadProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProgress = await _progressService.loadAllUserProgress();
      _progressIndex = await _progressService.loadProgressIndex();
    } catch (e) {
      AppLogger.error('Error loading progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new progress entry
  Future<void> saveProgress(UserProgress progress) async {
    try {
      await _progressService.saveUserProgress(progress);

      // Add to our local lists
      _userProgress.add(progress);

      // Update index
      _progressIndex.add({
        'chart_id': progress.chartId,
        'title': progress.title,
        'timestamp': progress.timestamp,
        'score': progress.score,
        'correct': progress.correct,
        'difficulty': progress.difficulty,
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error saving progress: $e');
    }
  }

  /// Clear all progress data
  Future<void> clearAllProgress() async {
    try {
      await _progressService.clearAllProgress();
      _userProgress = [];
      _progressIndex = [];
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error clearing progress: $e');
    }
  }

  /// Get progress statistics
  ProgressStats getProgressStats() {
    if (_userProgress.isEmpty) {
      return ProgressStats(
        totalChallenges: 0,
        correctChallenges: 0,
        averageScore: 0.0,
      );
    }

    final totalChallenges = _userProgress.length;
    final correctChallenges = _userProgress.where((p) => p.correct).length;
    final totalScore = _userProgress.fold(0, (sum, p) => sum + p.score);
    final averageScore = totalChallenges > 0
        ? totalScore / totalChallenges
        : 0.0;

    return ProgressStats(
      totalChallenges: totalChallenges,
      correctChallenges: correctChallenges,
      averageScore: averageScore.toDouble(),
    );
  }
}

class ProgressStats {
  final int totalChallenges;
  final int correctChallenges;
  final double averageScore;

  ProgressStats({
    required this.totalChallenges,
    required this.correctChallenges,
    required this.averageScore,
  });
}
