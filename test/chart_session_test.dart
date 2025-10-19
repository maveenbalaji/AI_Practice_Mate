import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/models/chart_session.dart';

void main() {
  group('ChartSession', () {
    test('ChartSession can be created with required fields', () {
      final currentProblem = CurrentProblem(
        problemId: 'test_problem_001',
        title: 'Test Problem',
        description: 'A test problem',
        inputFormat: 'None',
        outputFormat: 'None',
        exampleInput: '1',
        exampleOutput: '1',
        difficulty: 'Easy',
        status: 'in_progress',
      );

      final progress = Progress(
        attempts: 0,
        correct: false,
        score: 0,
        feedback: 'New challenge',
        timeSpent: '0 seconds',
      );

      final chartSession = ChartSession(
        chartId: 'test_chart_001',
        chartTitle: 'Test Chart',
        createdAt: '2025-10-15T10:00:00Z',
        lastUpdated: '2025-10-15T10:00:00Z',
        currentProblem: currentProblem,
        progress: progress,
        history: [],
      );

      expect(chartSession.chartId, 'test_chart_001');
      expect(chartSession.chartTitle, 'Test Chart');
      expect(chartSession.currentProblem.problemId, 'test_problem_001');
      expect(chartSession.progress.attempts, 0);
      expect(chartSession.history.length, 0);
    });

    test('CurrentProblem copyWith works correctly', () {
      final currentProblem = CurrentProblem(
        problemId: 'test_problem_001',
        title: 'Test Problem',
        description: 'A test problem',
        inputFormat: 'None',
        outputFormat: 'None',
        exampleInput: '1',
        exampleOutput: '1',
        difficulty: 'Easy',
        status: 'in_progress',
      );

      final updatedProblem = currentProblem.copyWith(status: 'completed');

      expect(updatedProblem.problemId, currentProblem.problemId);
      expect(updatedProblem.title, currentProblem.title);
      expect(updatedProblem.status, 'completed');
      expect(currentProblem.status, 'in_progress');
    });
  });
}
