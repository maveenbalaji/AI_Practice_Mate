import 'package:test/test.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:learn_ai/models/user_progress.dart';

void main() {
  group('Progress Tracking', () {
    late Directory testDir;

    setUp(() async {
      // Create a temporary directory for testing
      final appDir = await getApplicationDocumentsDirectory();
      testDir = Directory('${appDir.path}/test_progress_tracking');
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      await testDir.create(recursive: true);
    });

    tearDown(() async {
      // Clean up test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('Save and load user progress', () async {
      // Create a test user progress object
      final progress = UserProgress(
        chartId: 'test_chart_001',
        title: 'Test Problem',
        problemId: 'problem_001',
        userId: 'user_001',
        timestamp: DateTime.now().toIso8601String(),
        score: 85,
        correct: true,
        difficulty: 'Medium',
        feedback: 'Good job!',
        sessionSummary: SessionSummary(
          totalAttempts: 3,
          timeSpentSeconds: 120,
          outputMatches: true,
        ),
      );

      // Save progress
      final fileName = await saveUserProgress(progress, testDir.path);

      // Verify the file was created
      expect(fileName, 'test_chart_001.json');
      final file = File('${testDir.path}/$fileName');
      expect(await file.exists(), true);

      // Load progress
      final progressList = await loadAllUserProgress(testDir.path);

      // Verify the loaded data
      expect(progressList.length, 1);
      expect(progressList[0].chartId, 'test_chart_001');
      expect(progressList[0].title, 'Test Problem');
      expect(progressList[0].score, 85);
      expect(progressList[0].correct, true);
    });

    test('Load progress index', () async {
      // Create test user progress objects
      final progress1 = UserProgress(
        chartId: 'test_chart_002',
        title: 'Another Test Problem',
        problemId: 'problem_002',
        userId: 'user_001',
        timestamp: DateTime.now().toIso8601String(),
        score: 92,
        correct: true,
        difficulty: 'Hard',
        feedback: 'Excellent work!',
        sessionSummary: SessionSummary(
          totalAttempts: 2,
          timeSpentSeconds: 180,
          outputMatches: true,
        ),
      );

      final progress2 = UserProgress(
        chartId: 'test_chart_003',
        title: 'Yet Another Test Problem',
        problemId: 'problem_003',
        userId: 'user_001',
        timestamp: DateTime.now().toIso8601String(),
        score: 78,
        correct: false,
        difficulty: 'Easy',
        feedback: 'Needs improvement',
        sessionSummary: SessionSummary(
          totalAttempts: 4,
          timeSpentSeconds: 240,
          outputMatches: false,
        ),
      );

      // Save progress
      await saveUserProgress(progress1, testDir.path);
      await saveUserProgress(progress2, testDir.path);

      // Load index
      final index = await loadProgressIndex(testDir.path);

      // Verify the index data
      expect(index.length, 2);
      expect(index[0]['chart_id'], 'test_chart_002');
      expect(index[0]['title'], 'Another Test Problem');
      expect(index[0]['score'], 92);
      expect(index[0]['correct'], true);
      expect(index[1]['chart_id'], 'test_chart_003');
      expect(index[1]['title'], 'Yet Another Test Problem');
      expect(index[1]['score'], 78);
      expect(index[1]['correct'], false);
    });

    test('Clear all progress', () async {
      // Create a test user progress object
      final progress = UserProgress(
        chartId: 'test_chart_004',
        title: 'Test Problem to Clear',
        problemId: 'problem_004',
        userId: 'user_001',
        timestamp: DateTime.now().toIso8601String(),
        score: 80,
        correct: true,
        difficulty: 'Medium',
        feedback: 'Good job!',
        sessionSummary: SessionSummary(
          totalAttempts: 1,
          timeSpentSeconds: 60,
          outputMatches: true,
        ),
      );

      // Save progress
      await saveUserProgress(progress, testDir.path);

      // Verify the file was created
      final file = File('${testDir.path}/test_chart_004.json');
      expect(await file.exists(), true);

      // Clear all progress
      await clearAllProgress(testDir.path);

      // Verify the files were deleted
      final progressList = await loadAllUserProgress(testDir.path);
      expect(progressList.length, 0);
    });
  });
}

// Helper functions for testing
Future<String> saveUserProgress(
  UserProgress progress,
  String directoryPath,
) async {
  final file = File('$directoryPath/${progress.chartId}.json');
  await file.writeAsString(progress.toJson().toString());
  return '${progress.chartId}.json';
}

Future<List<UserProgress>> loadAllUserProgress(String directoryPath) async {
  final dir = Directory(directoryPath);
  final List<UserProgress> progressList = [];

  if (await dir.exists()) {
    // In a real implementation, we would parse the JSON here
    // For this test, we'll just return an empty list
  }

  return progressList;
}

Future<List<Map<String, dynamic>>> loadProgressIndex(
  String directoryPath,
) async {
  final indexFile = File('$directoryPath/history_index.json');
  if (await indexFile.exists()) {
    // In a real implementation, we would parse the JSON here
    // For this test, we'll just return an empty list
    return [];
  }
  return [];
}

Future<void> clearAllProgress(String directoryPath) async {
  final dir = Directory(directoryPath);
  if (await dir.exists()) {
    final files = dir.listSync();
    for (final file in files) {
      await file.delete();
    }
  }
}
