import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learn_ai/services/judge0_service.dart';

/// Test script to verify Judge0 API integration
Future<void> main() async {
  print('Testing Judge0 API integration...');

  // Test 1: Direct API call
  print('\n--- Test 1: Direct API Call ---');
  await testDirectApiCall();

  // Test 2: Using Judge0Service
  print('\n--- Test 2: Using Judge0Service ---');
  await testJudge0Service();
}

Future<void> testDirectApiCall() async {
  final String userCode = '''
print("Hello, World!")
print("This is a test of the Judge0 API")
''';

  print('Code to execute:');
  print(userCode);

  final url = Uri.parse(
    'https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true',
  );
  final response = await http.post(
    url,
    headers: {
      'x-rapidapi-host': 'judge0-ce.p.rapidapi.com',
      'x-rapidapi-key': '8b561332f1msh2116239b3985595p15c552jsn214ebbda8351',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'source_code': userCode,
      'language_id': 71, // Python
    }),
  );

  print('Response Status Code: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 201) {
    final result = jsonDecode(response.body);
    print('Success! Output: ${result['stdout']}');
  } else {
    print('Failed to execute code.');
    if (response.statusCode == 429) {
      print(
        'Quota exceeded. This is expected if the daily limit has been reached.',
      );
    }
  }
}

Future<void> testJudge0Service() async {
  final String userCode = '''
print("Hello, World!")
print("This is a test of the Judge0Service")
''';

  print('Code to execute:');
  print(userCode);

  final judge0Service = Judge0Service();
  final result = await judge0Service.executeCode(
    sourceCode: userCode,
    language: 'Python',
  );

  if (result != null) {
    final output = judge0Service.getFormattedOutput(result);
    print('Formatted Output:');
    print(output);
  } else {
    print('Failed to execute code through Judge0Service.');
  }
}
