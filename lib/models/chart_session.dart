import 'package:json_annotation/json_annotation.dart';

part 'chart_session.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChartSession {
  final String chartId;
  final String chartTitle;
  final String createdAt;
  final String lastUpdated;
  final CurrentProblem currentProblem;
  final Progress progress;
  final List<ProblemHistory> history;

  ChartSession({
    required this.chartId,
    required this.chartTitle,
    required this.createdAt,
    required this.lastUpdated,
    required this.currentProblem,
    required this.progress,
    required this.history,
  });

  factory ChartSession.fromJson(Map<String, dynamic> json) =>
      _$ChartSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChartSessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CurrentProblem {
  final String problemId;
  final String title;
  final String description;
  final String inputFormat;
  final String outputFormat;
  final String exampleInput;
  final String exampleOutput;
  final String difficulty;
  final String status; // "in_progress" | "completed"

  CurrentProblem({
    required this.problemId,
    required this.title,
    required this.description,
    required this.inputFormat,
    required this.outputFormat,
    required this.exampleInput,
    required this.exampleOutput,
    required this.difficulty,
    required this.status,
  });

  // CopyWith method for creating a copy with modified properties
  CurrentProblem copyWith({
    String? problemId,
    String? title,
    String? description,
    String? inputFormat,
    String? outputFormat,
    String? exampleInput,
    String? exampleOutput,
    String? difficulty,
    String? status,
  }) {
    return CurrentProblem(
      problemId: problemId ?? this.problemId,
      title: title ?? this.title,
      description: description ?? this.description,
      inputFormat: inputFormat ?? this.inputFormat,
      outputFormat: outputFormat ?? this.outputFormat,
      exampleInput: exampleInput ?? this.exampleInput,
      exampleOutput: exampleOutput ?? this.exampleOutput,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
    );
  }

  factory CurrentProblem.fromJson(Map<String, dynamic> json) =>
      _$CurrentProblemFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentProblemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Progress {
  final int attempts;
  final bool correct;
  final int score;
  final String feedback;
  final String timeSpent;

  Progress({
    required this.attempts,
    required this.correct,
    required this.score,
    required this.feedback,
    required this.timeSpent,
  });

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProblemHistory {
  final String problemId;
  final String title;
  final int score;
  final String difficulty;
  final bool correct;
  final String feedback;
  final String timestamp;

  ProblemHistory({
    required this.problemId,
    required this.title,
    required this.score,
    required this.difficulty,
    required this.correct,
    required this.feedback,
    required this.timestamp,
  });

  factory ProblemHistory.fromJson(Map<String, dynamic> json) =>
      _$ProblemHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemHistoryToJson(this);
}
