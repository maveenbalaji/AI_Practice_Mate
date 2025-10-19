import 'package:json_annotation/json_annotation.dart';

part 'user_progress.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProgress {
  final String chartId;
  final String userId;
  final String timestamp;
  final String problemId;
  final String title;
  final int score;
  final String feedback;
  final bool correct;
  final String difficulty;
  final SessionSummary sessionSummary;

  UserProgress({
    required this.chartId,
    required this.userId,
    required this.timestamp,
    required this.problemId,
    required this.title,
    required this.score,
    required this.feedback,
    required this.correct,
    required this.difficulty,
    required this.sessionSummary,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SessionSummary {
  final int totalAttempts;
  final int timeSpentSeconds;
  final bool outputMatches;

  SessionSummary({
    required this.totalAttempts,
    required this.timeSpentSeconds,
    required this.outputMatches,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SessionSummaryToJson(this);
}
