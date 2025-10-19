class TestCase {
  final String input;
  final String expectedOutput;

  TestCase({required this.input, required this.expectedOutput});

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input'] as String,
      expectedOutput: json['expected_output'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['input'] = input;
    data['expected_output'] = expectedOutput;
    return data;
  }
}
