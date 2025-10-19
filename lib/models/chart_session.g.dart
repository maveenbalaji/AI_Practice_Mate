// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChartSession _$ChartSessionFromJson(Map<String, dynamic> json) => ChartSession(
  chartId: json['chart_id'] as String,
  chartTitle: json['chart_title'] as String,
  createdAt: json['created_at'] as String,
  lastUpdated: json['last_updated'] as String,
  currentProblem: CurrentProblem.fromJson(
    json['current_problem'] as Map<String, dynamic>,
  ),
  progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
  history: (json['history'] as List<dynamic>)
      .map((e) => ProblemHistory.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChartSessionToJson(ChartSession instance) =>
    <String, dynamic>{
      'chart_id': instance.chartId,
      'chart_title': instance.chartTitle,
      'created_at': instance.createdAt,
      'last_updated': instance.lastUpdated,
      'current_problem': instance.currentProblem,
      'progress': instance.progress,
      'history': instance.history,
    };

CurrentProblem _$CurrentProblemFromJson(Map<String, dynamic> json) =>
    CurrentProblem(
      problemId: json['problem_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      inputFormat: json['input_format'] as String,
      outputFormat: json['output_format'] as String,
      exampleInput: json['example_input'] as String,
      exampleOutput: json['example_output'] as String,
      difficulty: json['difficulty'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$CurrentProblemToJson(CurrentProblem instance) =>
    <String, dynamic>{
      'problem_id': instance.problemId,
      'title': instance.title,
      'description': instance.description,
      'input_format': instance.inputFormat,
      'output_format': instance.outputFormat,
      'example_input': instance.exampleInput,
      'example_output': instance.exampleOutput,
      'difficulty': instance.difficulty,
      'status': instance.status,
    };

Progress _$ProgressFromJson(Map<String, dynamic> json) => Progress(
  attempts: (json['attempts'] as num).toInt(),
  correct: json['correct'] as bool,
  score: (json['score'] as num).toInt(),
  feedback: json['feedback'] as String,
  timeSpent: json['time_spent'] as String,
);

Map<String, dynamic> _$ProgressToJson(Progress instance) => <String, dynamic>{
  'attempts': instance.attempts,
  'correct': instance.correct,
  'score': instance.score,
  'feedback': instance.feedback,
  'time_spent': instance.timeSpent,
};

ProblemHistory _$ProblemHistoryFromJson(Map<String, dynamic> json) =>
    ProblemHistory(
      problemId: json['problem_id'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toInt(),
      difficulty: json['difficulty'] as String,
      correct: json['correct'] as bool,
      feedback: json['feedback'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$ProblemHistoryToJson(ProblemHistory instance) =>
    <String, dynamic>{
      'problem_id': instance.problemId,
      'title': instance.title,
      'score': instance.score,
      'difficulty': instance.difficulty,
      'correct': instance.correct,
      'feedback': instance.feedback,
      'timestamp': instance.timestamp,
    };
