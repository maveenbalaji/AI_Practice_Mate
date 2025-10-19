import 'package:flutter/material.dart';
import '../models/chart_session.dart';
import '../services/chart_integration_service.dart';
import '../services/logger_service.dart'; // Add this import
import 'chat_screen.dart';

class ChartHistoryScreen extends StatefulWidget {
  const ChartHistoryScreen({super.key});

  @override
  State<ChartHistoryScreen> createState() => _ChartHistoryScreenState();
}

class _ChartHistoryScreenState extends State<ChartHistoryScreen> {
  final ChartIntegrationService _chartIntegrationService =
      ChartIntegrationService();
  List<ChartSession> _chartSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartSessions();
  }

  Future<void> _loadChartSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _chartIntegrationService.loadAllChartSessions();
      setState(() {
        _chartSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading chart sessions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshChartSessions() async {
    await _loadChartSessions();
  }

  Future<void> _deleteChartSession(String chartId) async {
    try {
      await _chartIntegrationService.deleteChartSession(chartId);
      _loadChartSessions(); // Refresh the list
    } catch (e) {
      AppLogger.error('Error deleting chart session: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting session')));
      }
    }
  }

  void _openChartSession(ChartSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          language: '', // Will be extracted from chart title
          topic: '', // Will be extracted from chart title
          initialSession: session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChartSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chartSessions.isEmpty
          ? const Center(
              child: Text(
                'No chart sessions yet.\nStart a new coding challenge to see it here!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _chartSessions.length,
              itemBuilder: (context, index) {
                final session = _chartSessions[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(session.chartTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created: ${_formatDateTime(session.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Last updated: ${_formatDateTime(session.lastUpdated)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Problems solved: ${session.history.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (session.progress.attempts > 0)
                          Text(
                            'Current problem: ${session.currentProblem.title}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDeleteSession(session);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () => _openChartSession(session),
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void _confirmDeleteSession(ChartSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete the session "${session.chartTitle}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChartSession(session.chartId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
