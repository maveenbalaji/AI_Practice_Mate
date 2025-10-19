import 'dart:convert';
import 'package:http/http.dart' as http;

class Judge0Service {
  static const String _baseUrl = 'https://judge0-ce.p.rapidapi.com';
  static const String _apiKey =
      '8b561332f1msh2116239b3985595p15c552jsn214ebbda8351';

  // Language ID mappings for Judge0
  static const Map<String, int> languageIds = {
    'Python': 71,
    'Java': 62,
    'C++': 54,
    'JavaScript': 63,
    'C#': 51,
    'Go': 60,
    'Ruby': 72,
    'PHP': 68,
    'Swift': 83,
    'Kotlin': 78,
  };

  /// Execute code using Judge0 API
  Future<Map<String, dynamic>?> executeCode({
    required String sourceCode,
    required String language,
    String? stdin,
  }) async {
    try {
      // Get language ID
      final languageId = languageIds[language];
      if (languageId == null) {
        throw Exception('Unsupported language: $language');
      }

      // Prepare request body
      final requestBody = {
        'source_code': sourceCode,
        'language_id': languageId,
        'stdin': stdin ?? '',
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/submissions?base64_encoded=false&wait=true'),
        headers: {
          'x-rapidapi-host': 'judge0-ce.p.rapidapi.com',
          'x-rapidapi-key': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Enhanced error handling
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        // More detailed error logging
        print('Judge0 API error:');
        print('  Status Code: ${response.statusCode}');
        print('  Response Body: ${response.body}');
        print(
          '  Request Headers: x-rapidapi-host=judge0-ce.p.rapidapi.com, content-type=application/json',
        );
        print('  Request Body: ${jsonEncode(requestBody)}');

        // Return error information to be displayed to user
        return {
          'error': true,
          'status_code': response.statusCode,
          'message': response.body,
        };
      }
    } catch (e) {
      print('Error executing code with Judge0: $e');
      return {'error': true, 'message': 'Network error or exception: $e'};
    }
  }

  /// Get formatted output from execution result
  String getFormattedOutput(Map<String, dynamic> result) {
    // Handle error responses
    if (result.containsKey('error')) {
      final statusCode = result['status_code'];
      final message = result['message'] as String? ?? 'Unknown error';

      if (statusCode == 429) {
        return 'API Quota Exceeded: You have exceeded the daily quota for code executions. Please try again tomorrow or upgrade your plan.';
      }

      return 'Execution Error (Status $statusCode): $message';
    }

    final stdout = result['stdout'] as String? ?? '';
    final stderr = result['stderr'] as String? ?? '';
    final compileOutput = result['compile_output'] as String? ?? '';
    final status = result['status'] as Map<String, dynamic>? ?? {};

    final statusDescription =
        status['description'] as String? ?? 'Unknown status';

    // If there's a compilation error, show it
    if (compileOutput.isNotEmpty) {
      return 'Compilation Error:\n$compileOutput';
    }

    // If there's a runtime error, show it
    if (stderr.isNotEmpty) {
      return 'Runtime Error:\n$stderr';
    }

    // If execution was successful, show the output
    if (stdout.isNotEmpty) {
      return stdout;
    }

    // Otherwise, show the status
    return 'Execution completed with status: $statusDescription';
  }
}
