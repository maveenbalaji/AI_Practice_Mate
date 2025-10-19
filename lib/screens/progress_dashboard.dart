import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/progress_provider.dart';
import '../models/user_progress.dart';
import 'progress_chart_screen.dart';
import 'chart_history_screen.dart'; // Add this import

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  @override
  void initState() {
    super.initState();
    // Load progress data when the dashboard is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressProvider>(context, listen: false).loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Learning Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: progressProvider.loadProgress,
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Stats summary
                if (!progressProvider.isLoading) ...[
                  _buildStatsSummary(progressProvider),
                  const Divider(),

                  // Charts section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '📊 User Charts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildScoreTrendChart(progressProvider.userProgress),
                  const SizedBox(height: 20),

                  // History section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '🕒 History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300, // Fixed height for history list
                    child: _buildHistoryList(progressProvider.userProgress),
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChartHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('View Chart History'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: progressProvider.clearAllProgress,
                          icon: const Icon(Icons.delete),
                          label: const Text('Clear History'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.download),
                          label: const Text('Export Data'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Add some bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build stats summary section
  Widget _buildStatsSummary(ProgressProvider progressProvider) {
    final stats = progressProvider.getProgressStats();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Challenges',
                stats.totalChallenges.toString(),
                Icons.task,
              ),
              _buildStatCard(
                'Correct',
                stats.correctChallenges.toString(),
                Icons.check_circle,
              ),
              _buildStatCard(
                'Avg Score',
                '${stats.averageScore.toStringAsFixed(1)}%',
                Icons.score,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a stat card
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// Build score trend chart
  Widget _buildScoreTrendChart(List<UserProgress> progressList) {
    if (progressList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No data available for chart'),
      );
    }

    // Take the last 10 entries for the chart
    final recentProgress = progressList.length > 10
        ? progressList.sublist(progressList.length - 10)
        : progressList;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: true),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: recentProgress.length.toDouble() - 1,
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: recentProgress.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.score.toDouble(),
                  );
                }).toList(),
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build history list
  Widget _buildHistoryList(List<UserProgress> progressList) {
    if (progressList.isEmpty) {
      return const Center(child: Text('No history available'));
    }

    // Sort by timestamp (newest first)
    final sortedList = List<UserProgress>.from(progressList)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final progress = sortedList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(progress.title),
            subtitle: Text(
              '${progress.timestamp.substring(0, 10)} • Score: ${progress.score} • ${progress.difficulty}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              progress.correct ? Icons.check_circle : Icons.cancel,
              color: progress.correct ? Colors.green : Colors.red,
            ),
            onTap: () => _navigateToProgressChart(progress),
          ),
        );
      },
    );
  }

  /// Navigate to progress chart screen
  void _navigateToProgressChart(UserProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressChartScreen(progress: progress),
      ),
    );
  }

  /// Export data function
  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Export functionality will be implemented in a future update',
        ),
      ),
    );
  }
}
