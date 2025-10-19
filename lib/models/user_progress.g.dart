// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
  chartId: json['chart_id'] as String,
  userId: json['user_id'] as String,
  timestamp: json['timestamp'] as String,
  problemId: json['problem_id'] as String,
  title: json['title'] as String,
  score: (json['score'] as num).toInt(),
  feedback: json['feedback'] as String,
  correct: json['correct'] as bool,
  difficulty: json['difficulty'] as String,
  sessionSummary: SessionSummary.fromJson(
    json['session_summary'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'chart_id': instance.chartId,
      'user_id': instance.userId,
      'timestamp': instance.timestamp,
      'problem_id': instance.problemId,
      'title': instance.title,
      'score': instance.score,
      'feedback': instance.feedback,
      'correct': instance.correct,
      'difficulty': instance.difficulty,
      'session_summary': instance.sessionSummary,
    };

SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    SessionSummary(
      totalAttempts: (json['total_attempts'] as num).toInt(),
      timeSpentSeconds: (json['time_spent_seconds'] as num).toInt(),
      outputMatches: json['output_matches'] as bool,
    );

Map<String, dynamic> _$SessionSummaryToJson(SessionSummary instance) =>
    <String, dynamic>{
      'total_attempts': instance.totalAttempts,
      'time_spent_seconds': instance.timeSpentSeconds,
      'output_matches': instance.outputMatches,
    };
