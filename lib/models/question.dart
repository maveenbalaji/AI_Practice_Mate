import 'test_case.dart';

class Question {
  final String id;
  final String title;
  final String description;
  final String topic;
  final String language;
  final int difficulty;
  final String? inputFormat;
  final String? outputFormat;
  final List<TestCase>? testCases;
  final String? hint;

  Question({
    required this.id,
    required this.title,
    required this.description,
    required this.topic,
    required this.language,
    required this.difficulty,
    this.inputFormat,
    this.outputFormat,
    this.testCases,
    this.hint,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<TestCase>? testCases;
    if (json['test_cases'] != null) {
      testCases = (json['test_cases'] as List)
          .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Question(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      topic: json['topic'] as String,
      language: json['language'] as String,
      difficulty: json['difficulty'] as int,
      inputFormat: json['input_format'] as String?,
      outputFormat: json['output_format'] as String?,
      testCases: testCases,
      hint: json['hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['topic'] = topic;
    data['language'] = language;
    data['difficulty'] = difficulty;
    if (inputFormat != null) data['input_format'] = inputFormat;
    if (outputFormat != null) data['output_format'] = outputFormat;
    if (testCases != null) {
      data['test_cases'] = testCases!.map((e) => e.toJson()).toList();
    }
    if (hint != null) data['hint'] = hint;
    return data;
  }

  // Get difficulty level as string
  String get difficultyLevel {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Medium';
      case 5:
        return 'Hard';
      default:
        return 'Easy';
    }
  }
}
