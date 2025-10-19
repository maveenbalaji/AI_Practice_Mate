import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../models/chart_session.dart';
import 'chat_screen.dart';

class ProgressChartScreen extends StatelessWidget {
  final UserProgress progress;

  const ProgressChartScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(progress.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh logic can be added here if needed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            progress.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          progress.correct ? Icons.check_circle : Icons.cancel,
                          color: progress.correct ? Colors.green : Colors.red,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Date', progress.timestamp.substring(0, 10)),
                    _buildInfoRow('Score', '${progress.score}/100'),
                    _buildInfoRow('Difficulty', progress.difficulty),
                    _buildInfoRow('Correct', progress.correct ? 'Yes' : 'No'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feedback Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progress.feedback,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Session Summary
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Attempts',
                      progress.sessionSummary.totalAttempts.toString(),
                    ),
                    _buildInfoRow(
                      'Time Spent',
                      '${progress.sessionSummary.timeSpentSeconds} seconds',
                    ),
                    _buildInfoRow(
                      'Output Matches',
                      progress.sessionSummary.outputMatches ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Challenge Details (if available)
            if (progress.problemId.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Challenge Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('Problem ID', progress.problemId),
                      _buildInfoRow('User ID', progress.userId),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implement resume chart functionality
                      _resumeChart(context);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume Chart'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build information rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  /// Resume chart functionality
  void _resumeChart(BuildContext context) {
    // Create a chart session from the user progress
    final chartSession = ChartSession(
      chartId: progress.chartId,
      chartTitle: progress.title,
      createdAt: progress.timestamp,
      lastUpdated: DateTime.now().toIso8601String(),
      currentProblem: CurrentProblem(
        problemId: progress.problemId,
        title: progress.title,
        description: 'Resume previous challenge',
        inputFormat: '',
        outputFormat: '',
        exampleInput: '',
        exampleOutput: '',
        difficulty: progress.difficulty,
        status: 'in_progress',
      ),
      progress: Progress(
        attempts: progress.sessionSummary.totalAttempts,
        correct: progress.correct,
        score: progress.score,
        feedback: progress.feedback,
        timeSpent: '${progress.sessionSummary.timeSpentSeconds} seconds',
      ),
      history: [
        ProblemHistory(
          problemId: progress.problemId,
          title: progress.title,
          score: progress.score,
          difficulty: progress.difficulty,
          correct: progress.correct,
          feedback: progress.feedback,
          timestamp: progress.timestamp,
        ),
      ],
    );

    // Navigate to the chat screen with the chart session
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          language: 'Python', // Default language, could be stored in progress
          topic: progress.title, // Use title as topic
          initialSession: chartSession,
        ),
      ),
    );
  }
}
