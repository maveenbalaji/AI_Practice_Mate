import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/evaluation_result.dart';
import '../models/test_case.dart';

class AIService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  // Get API key from environment variables
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Headers for API requests
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  /// Generate a coding challenge based on topic, language, and difficulty
  Future<Question?> generateChallenge({
    required String topic,
    required String language,
    required int difficulty,
  }) async {
    try {
      final payload = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _getSystemPrompt()},
          {
            'role': 'user',
            'content': jsonEncode({
              'action': 'generate_question',
              'language': language,
              'topic': topic,
              'difficulty': _getDifficultyString(difficulty),
            }),
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final aiResponse = jsonResponse['choices'][0]['message']['content'];

        // Parse the AI response to extract question details
        return _parseQuestionFromAIResponse(aiResponse);
      } else {
        print('Failed to generate challenge: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } on SocketException {
      print('No internet connection');
      return null;
    } on HttpException {
      print('HTTP error occurred');
      return null;
    } catch (e) {
      print('Error generating challenge: $e');
      return null;
    }
  }

  /// Evaluate user's code solution
  Future<Map<String, dynamic>?> evaluateCode({
    required String code,
    required Question question,
  }) async {
    try {
      final payload = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _getSystemPrompt()},
          {
            'role': 'user',
            'content': jsonEncode({
              'action': 'evaluate_code',
              'language': question.language,
              'problem_id': question.id,
              'problem_title': question.title,
              'problem_spec': {
                'description': question.description,
                'input_format': question.inputFormat,
                'output_format': question.outputFormat,
                'example_input': question.testCases?.isNotEmpty == true
                    ? question.testCases!.first.input
                    : '',
                'example_output': question.testCases?.isNotEmpty == true
                    ? question.testCases!.first.expectedOutput
                    : '',
                'difficulty': question.difficultyLevel,
              },
              'user_code': code,
              'requirements': [
                'If code prints the exact required output for example_output, mark as correct.',
                'Consider trailing spaces/newlines acceptable if output matches tokens.',
                'If code is logically correct but print format differs (no spaces), treat as minor error and suggest fix.',
              ],
            }),
          },
        ],
        'temperature': 0.3,
        'max_tokens': 1500,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final aiResponse = jsonResponse['choices'][0]['message']['content'];

        // Parse the AI response to extract both evaluation and next question
        return _parseEvaluationAndNextQuestion(aiResponse);
      } else {
        print('Failed to evaluate code: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } on SocketException {
      print('No internet connection');
      return null;
    } on HttpException {
      print('HTTP error occurred');
      return null;
    } catch (e) {
      print('Error evaluating code: $e');
      return null;
    }
  }

  /// Get a hint for the current question
  Future<String?> getHint(Question question) async {
    try {
      final payload = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _getHintPrompt()},
          {
            'role': 'user',
            'content': jsonEncode({
              'action': 'get_hint',
              'language': question.language,
              'problem_id': question.id,
              'problem_title': question.title,
              'problem_spec': {
                'description': question.description,
                'input_format': question.inputFormat,
                'output_format': question.outputFormat,
                'example_input': question.testCases?.isNotEmpty == true
                    ? question.testCases!.first.input
                    : '',
                'example_output': question.testCases?.isNotEmpty == true
                    ? question.testCases!.first.expectedOutput
                    : '',
                'difficulty': question.difficultyLevel,
              },
            }),
          },
        ],
        'temperature': 0.5,
        'max_tokens': 500,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        print('Failed to get hint: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting hint: $e');
      return null;
    }
  }

  /// System prompt for generating challenges and evaluations
  String _getSystemPrompt() {
    return '''
You are CodeSensei, an AI coding mentor for programming learners.

You must always respond in *strict JSON format* only. 
Never use markdown, emojis, or text outside the JSON block.

### Output Schema:
{
  "type": "evaluation",
  "evaluation": {
    "problem_id": "string",
    "correct": true | false,
    "feedback": "string",
    "score": number (0-100)
  },
  "next_question": {
    "problem_id": "string",
    "title": "string",
    "description": "string",
    "input_format": "string",
    "output_format": "string",
    "example_input": "string",
    "example_output": "string",
    "difficulty": "Easy" | "Medium" | "Hard"
  }
}

### BEHAVIOR RULES:

1. You are teaching by giving programming challenges.
   - Start easy and increase difficulty as the learner progresses.
   - Always include input/output examples and difficulty level.

2. When the user submits their code:
   - Simulate running it in your head.
   - Compare the output logically to the example output.
   - Set evaluation.correct = true if it produces the correct output or a logically correct equivalent.

3. If the solution is correct:
   - evaluation.correct = true
   - evaluation.feedback = a short congratulatory message and learning tip.
   - Immediately include the **next question** in the "next_question" field (difficulty should increase slightly).

4. If the solution is wrong:
   - evaluation.correct = false
   - evaluation.feedback = short hint and encouragement.
   - Set "next_question": null.

5. Always return *exactly one JSON object* per response — no extra text, no markdown.

6. Never skip next_question when evaluation.correct = true.

--- 

Example of correct response when user code is correct:
{
  "type": "evaluation",
  "evaluation": {
    "problem_id": "python_loops_001",
    "correct": true,
    "feedback": "Well done! Your loop works perfectly. Let's try a slightly harder one.",
    "score": 100
  },
  "next_question": {
    "problem_id": "python_loops_002",
    "title": "Sum of Even Numbers",
    "description": "Write a program that reads an integer N and prints the sum of all even numbers from 1 to N.",
    "input_format": "Single integer N",
    "output_format": "Single integer (sum of even numbers up to N)",
    "example_input": "10",
    "example_output": "30",
    "difficulty": "Easy"
  }
}

Example of response when user code is incorrect:
{
  "type": "evaluation",
  "evaluation": {
    "problem_id": "python_loops_001",
    "correct": false,
    "feedback": "Almost there! Check your print formatting — make sure you include spaces between numbers.",
    "score": 60
  },
  "next_question": null
}

Return ONLY valid JSON - no extra text or markdown.
''';
  }

  /// System prompt for providing hints
  String _getHintPrompt() {
    return '''
You are CodeSensei, an AI coding mentor specialized in helping learners with programming challenges.

When providing a hint for a coding challenge, offer a gentle nudge in the right direction without giving away the complete solution. Focus on:

1. Identifying the core concept being tested
2. Suggesting an approach or algorithm
3. Pointing out common pitfalls to avoid
4. Providing pseudocode if helpful
5. Being encouraging and supportive

Keep your hint concise but helpful. Do not reveal the complete solution.

Return your response as plain text (not JSON).
''';
  }

  /// Parse question from AI response
  Question _parseQuestionFromAIResponse(String response) {
    try {
      // Extract JSON from response if it contains extra text
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(
          0,
          cleanedResponse.length - 3,
        );
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to parse as JSON
      final json = jsonDecode(cleanedResponse);

      // Handle both direct question format and wrapped format
      Map<String, dynamic> questionData;
      if (json['type'] == 'question' && json['next_question'] != null) {
        questionData = json['next_question'];
      } else if (json['title'] != null) {
        questionData = json;
      } else if (json['next_question'] != null) {
        questionData = json['next_question'];
      } else {
        throw Exception('Invalid question format');
      }

      // Convert difficulty string to int
      int difficulty = 1;
      if (questionData['difficulty'] is String) {
        switch (questionData['difficulty'].toString().toLowerCase()) {
          case 'easy':
            difficulty = 1;
            break;
          case 'medium':
            difficulty = 3;
            break;
          case 'hard':
            difficulty = 5;
            break;
          default:
            difficulty = 1;
        }
      } else if (questionData['difficulty'] is int) {
        difficulty = questionData['difficulty'];
      }

      // Create a test case from example input/output
      List<TestCase> testCases = [];
      if (questionData['example_input'] != null &&
          questionData['example_output'] != null) {
        testCases.add(
          TestCase(
            input: questionData['example_input'].toString(),
            expectedOutput: questionData['example_output'].toString(),
          ),
        );
      }

      return Question(
        id:
            questionData['problem_id']?.toString() ??
            'ai_\${DateTime.now().millisecondsSinceEpoch}',
        title: questionData['title'] as String,
        description: questionData['description'] as String,
        topic: '', // Will be set by the calling function
        language: '', // Will be set by the calling function
        difficulty: difficulty,
        inputFormat: questionData['input_format'] as String?,
        outputFormat: questionData['output_format'] as String?,
        testCases: testCases,
        hint: null,
      );
    } catch (e) {
      // If parsing fails, create a fallback question
      return Question(
        id: 'fallback_\${DateTime.now().millisecondsSinceEpoch}',
        title: 'Parsing Error',
        description:
            'There was an error parsing the AI response. Please try again.',
        topic: 'Error',
        language: 'Python',
        difficulty: 1,
        hint: 'The AI response could not be parsed correctly.',
      );
    }
  }

  /// Parse evaluation result and next question from AI response
  Map<String, dynamic> _parseEvaluationAndNextQuestion(String response) {
    try {
      // Extract JSON from response if it contains extra text
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(
          0,
          cleanedResponse.length - 3,
        );
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to parse as JSON
      final json = jsonDecode(cleanedResponse);

      // Extract evaluation data
      Map<String, dynamic> evaluationData = {};
      if (json['evaluation'] != null) {
        evaluationData = json['evaluation'];
      } else {
        evaluationData = json;
      }

      // Extract next question if available
      Question? nextQuestion;
      if (json['next_question'] != null && json['next_question'] is Map) {
        try {
          final nextQuestionData = json['next_question'];

          // Convert difficulty string to int
          int difficulty = 1;
          if (nextQuestionData['difficulty'] is String) {
            switch (nextQuestionData['difficulty'].toString().toLowerCase()) {
              case 'easy':
                difficulty = 1;
                break;
              case 'medium':
                difficulty = 3;
                break;
              case 'hard':
                difficulty = 5;
                break;
              default:
                difficulty = 1;
            }
          } else if (nextQuestionData['difficulty'] is int) {
            difficulty = nextQuestionData['difficulty'];
          }

          // Create a test case from example input/output
          List<TestCase> testCases = [];
          if (nextQuestionData['example_input'] != null &&
              nextQuestionData['example_output'] != null) {
            testCases.add(
              TestCase(
                input: nextQuestionData['example_input'].toString(),
                expectedOutput: nextQuestionData['example_output'].toString(),
              ),
            );
          }

          nextQuestion = Question(
            id:
                nextQuestionData['problem_id']?.toString() ??
                'ai_\${DateTime.now().millisecondsSinceEpoch}',
            title: nextQuestionData['title'] as String,
            description: nextQuestionData['description'] as String,
            topic: '', // Will be set by the calling function
            language: '', // Will be set by the calling function
            difficulty: difficulty,
            inputFormat: nextQuestionData['input_format'] as String?,
            outputFormat: nextQuestionData['output_format'] as String?,
            testCases: testCases,
            hint: null,
          );
        } catch (e) {
          print('Error parsing next question: \$e');
          nextQuestion = null;
        }
      }

      // Create evaluation result
      final evaluationResult = EvaluationResult(
        status: evaluationData['correct'] == true ? 'PASS' : 'FAIL',
        feedback:
            evaluationData['feedback'] as String? ?? 'No feedback provided',
        nextAction: evaluationData['correct'] == true
            ? 'NEXT_CHALLENGE'
            : 'TRY_AGAIN',
        canProgress: evaluationData['correct'] == true,
        xpEarned: evaluationData['score'] as int?,
      );

      return {'evaluation': evaluationResult, 'next_question': nextQuestion};
    } catch (e) {
      print('Error parsing evaluation and next question: \$e');
      // Return fallback evaluation
      return {
        'evaluation': EvaluationResult(
          status: 'ERROR',
          feedback:
              'There was an error evaluating your code. Please try again.',
          canProgress: false,
        ),
        'next_question': null,
      };
    }
  }

  /// Convert difficulty int to string
  String _getDifficultyString(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return 'Easy';
      case 3:
      case 4:
        return 'Medium';
      case 5:
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  /// Fetch available topics for a given programming language
  Future<List<String>> fetchTopicsForLanguage(String language) async {
    try {
      final payload = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content':
                'List all programming topics you can generate challenges for in $language. Respond with a JSON array of topic names only.',
          },
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final aiResponse = jsonResponse['choices'][0]['message']['content'];

        // Try to parse the response as a JSON array
        try {
          // Clean up the response to extract JSON array
          String cleanedResponse = aiResponse.trim();
          if (cleanedResponse.startsWith('```json')) {
            cleanedResponse = cleanedResponse.substring(7);
          }
          if (cleanedResponse.startsWith('```')) {
            cleanedResponse = cleanedResponse.substring(3);
          }
          if (cleanedResponse.endsWith('```')) {
            cleanedResponse = cleanedResponse.substring(
              0,
              cleanedResponse.length - 3,
            );
          }
          cleanedResponse = cleanedResponse.trim();

          // Parse as JSON array
          final List<dynamic> topics = jsonDecode(cleanedResponse);
          return topics.cast<String>();
        } catch (e) {
          print('Error parsing topics: $e');
          print('AI response: $aiResponse');
          // Return fallback topics if parsing fails
          return _getFallbackTopicsForLanguage(language);
        }
      } else {
        print('Failed to fetch topics: ${response.statusCode}');
        print('Response: ${response.body}');
        // Return fallback topics if API call fails
        return _getFallbackTopicsForLanguage(language);
      }
    } catch (e) {
      print('Error fetching topics: $e');
      // Return fallback topics if exception occurs
      return _getFallbackTopicsForLanguage(language);
    }
  }

  /// Get fallback topics for a language when API call fails
  List<String> _getFallbackTopicsForLanguage(String language) {
    final Map<String, List<String>> fallbackTopics = {
      'Python': [
        'Loops and Control Statements',
        'Functions',
        'Lists and Arrays',
        'Strings',
        'Dictionaries',
        'Classes and Objects',
        'File Handling',
        'Exception Handling',
      ],
      'Java': [
        'Loops and Control Statements',
        'Methods',
        'Arrays',
        'Strings',
        'Collections',
        'Classes and Objects',
        'File I/O',
        'Exception Handling',
      ],
      'JavaScript': [
        'Loops and Control Statements',
        'Functions',
        'Arrays',
        'Strings',
        'Objects',
        'Classes',
        'File Handling',
        'Error Handling',
      ],
      'C++': [
        'Loops and Control Statements',
        'Functions',
        'Arrays',
        'Strings',
        'STL',
        'Classes and Objects',
        'File Handling',
        'Exception Handling',
      ],
      'C#': [
        'Loops and Control Statements',
        'Methods',
        'Arrays',
        'Strings',
        'Collections',
        'Classes and Objects',
        'File I/O',
        'Exception Handling',
      ],
      'C': [
        'Loops and Control Statements',
        'Functions',
        'Arrays',
        'Strings',
        'Pointers',
        'Structures',
        'File Handling',
        'Preprocessor Directives',
      ],
      'Go': [
        'Loops and Control Statements',
        'Functions',
        'Arrays and Slices',
        'Strings',
        'Structures',
        'Interfaces',
        'File Handling',
        'Error Handling',
      ],
      'Rust': [
        'Loops and Control Statements',
        'Functions',
        'Arrays and Vectors',
        'Strings',
        'Structures',
        'Traits',
        'File Handling',
        'Error Handling',
      ],
      'Swift': [
        'Loops and Control Statements',
        'Functions',
        'Arrays',
        'Strings',
        'Structures',
        'Classes',
        'File Handling',
        'Error Handling',
      ],
      'Kotlin': [
        'Loops and Control Statements',
        'Functions',
        'Arrays',
        'Strings',
        'Classes',
        'Extensions',
        'File Handling',
        'Exception Handling',
      ],
    };

    return fallbackTopics[language] ??
        ['No topics available for this language'];
  }
}
