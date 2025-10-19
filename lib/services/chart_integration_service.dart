import 'package:uuid/uuid.dart';
import '../models/chart_session.dart';
import '../models/question.dart';
import '../services/logger_service.dart'; // Add this import
import 'ai_service.dart';
import 'chart_session_service.dart';

class ChartIntegrationService {
  final AIService _aiService = AIService();
  final ChartSessionService _chartSessionService = ChartSessionService();
  final Uuid _uuid = Uuid();

  /// Create a new chart session with an initial challenge
  Future<ChartSession?> createNewChartSession({
    required String language,
    required String topic,
    required int difficulty,
  }) async {
    try {
      // Generate the first challenge
      final question = await _aiService.generateChallenge(
        topic: topic,
        language: language,
        difficulty: difficulty,
      );

      if (question == null) {
        return null;
      }

      // Create a new chart session
      final chartId = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final currentProblem = CurrentProblem(
        problemId: question.id,
        title: question.title,
        description: question.description,
        inputFormat: question.inputFormat ?? '',
        outputFormat: question.outputFormat ?? '',
        exampleInput: question.testCases?.isNotEmpty == true
            ? question.testCases!.first.input
            : '',
        exampleOutput: question.testCases?.isNotEmpty == true
            ? question.testCases!.first.expectedOutput
            : '',
        difficulty: _getDifficultyString(question.difficulty),
        status: 'in_progress',
      );

      final progress = Progress(
        attempts: 0,
        correct: false,
        score: 0,
        feedback: 'New challenge started',
        timeSpent: '0 seconds',
      );

      final chartSession = ChartSession(
        chartId: chartId,
        chartTitle: '$language - $topic',
        createdAt: now,
        lastUpdated: now,
        currentProblem: currentProblem,
        progress: progress,
        history: [],
      );

      // Save the new chart session
      await _chartSessionService.saveChartSession(chartSession);

      return chartSession;
    } catch (e) {
      AppLogger.error('Error creating new chart session: $e');
      return null;
    }
  }

  /// Evaluate user code and update the chart session
  Future<ChartSession?> evaluateCodeAndAdvance({
    required ChartSession session,
    required String code,
  }) async {
    try {
      // Create a Question object from the current problem
      final question = Question(
        id: session.currentProblem.problemId,
        title: session.currentProblem.title,
        description: session.currentProblem.description,
        topic: session.chartTitle,
        language: '', // Will be determined by the AI service
        difficulty: _getDifficultyInt(session.currentProblem.difficulty),
        inputFormat: session.currentProblem.inputFormat,
        outputFormat: session.currentProblem.outputFormat,
        testCases: [
          // We don't have actual test cases here, but the AI service will handle evaluation
        ],
      );

      // Evaluate the code
      final result = await _aiService.evaluateCode(
        code: code,
        question: question,
      );

      if (result == null) {
        return null;
      }

      final evaluation = result['evaluation'];
      final nextQuestion = result['next_question'];

      // Update the session based on evaluation
      final now = DateTime.now().toUtc().toIso8601String();
      final updatedHistory = List<ProblemHistory>.from(session.history);

      // If the solution was correct, move current problem to history
      if (evaluation.status == 'PASS' && session.progress.attempts > 0) {
        updatedHistory.add(
          ProblemHistory(
            problemId: session.currentProblem.problemId,
            title: session.currentProblem.title,
            score: session.progress.score,
            difficulty: session.currentProblem.difficulty,
            correct: true,
            feedback: session.progress.feedback,
            timestamp: now,
          ),
        );
      }

      // Create updated progress
      final updatedProgress = Progress(
        attempts: session.progress.attempts + 1,
        correct: evaluation.status == 'PASS',
        score: evaluation.xpEarned ?? 0,
        feedback: evaluation.feedback,
        timeSpent:
            '0 seconds', // This would be calculated based on actual time tracking
      );

      CurrentProblem updatedCurrentProblem;

      // If we have a next question, update the current problem
      if (nextQuestion != null) {
        updatedCurrentProblem = CurrentProblem(
          problemId: nextQuestion.id,
          title: nextQuestion.title,
          description: nextQuestion.description,
          inputFormat: nextQuestion.inputFormat ?? '',
          outputFormat: nextQuestion.outputFormat ?? '',
          exampleInput: nextQuestion.testCases?.isNotEmpty == true
              ? nextQuestion.testCases!.first.input
              : '',
          exampleOutput: nextQuestion.testCases?.isNotEmpty == true
              ? nextQuestion.testCases!.first.expectedOutput
              : '',
          difficulty: _getDifficultyString(nextQuestion.difficulty),
          status: 'in_progress',
        );
      } else {
        // Keep the same problem if no next question
        updatedCurrentProblem = session.currentProblem.copyWith(
          status: evaluation.status == 'PASS' ? 'completed' : 'in_progress',
        );
      }

      // Create the updated session
      final updatedSession = ChartSession(
        chartId: session.chartId,
        chartTitle: session.chartTitle,
        createdAt: session.createdAt,
        lastUpdated: now,
        currentProblem: updatedCurrentProblem,
        progress: updatedProgress,
        history: updatedHistory,
      );

      // Save the updated session
      await _chartSessionService.saveChartSession(updatedSession);

      return updatedSession;
    } catch (e) {
      AppLogger.error('Error evaluating code and advancing: $e');
      return null;
    }
  }

  /// Load a chart session by ID
  Future<ChartSession?> loadChartSession(String chartId) async {
    return await _chartSessionService.loadChartSession(chartId);
  }

  /// Load all chart sessions
  Future<List<ChartSession>> loadAllChartSessions() async {
    return await _chartSessionService.loadAllChartSessions();
  }

  /// Delete a chart session
  Future<void> deleteChartSession(String chartId) async {
    await _chartSessionService.deleteChartSession(chartId);
  }

  /// Helper method to convert difficulty int to string
  String _getDifficultyString(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return 'Easy';
      case 3:
      case 4:
        return 'Medium';
      case 5:
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  /// Helper method to convert difficulty string to int
  int _getDifficultyInt(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 3;
      case 'hard':
        return 5;
      default:
        return 1;
    }
  }
}
