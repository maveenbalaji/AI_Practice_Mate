import 'test_case.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String topic;
  final String language;
  final int difficulty;
  final String? inputFormat;
  final String? outputFormat;
  final List<TestCase>? testCases;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.topic,
    required this.language,
    required this.difficulty,
    this.inputFormat,
    this.outputFormat,
    this.testCases,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    List<TestCase>? testCases;
    if (json['test_cases'] != null) {
      testCases = (json['test_cases'] as List)
          .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      topic: json['topic'] as String,
      language: json['language'] as String,
      difficulty: json['difficulty'] as int,
      inputFormat: json['input_format'] as String?,
      outputFormat: json['output_format'] as String?,
      testCases: testCases,
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
    return data;
  }
}
