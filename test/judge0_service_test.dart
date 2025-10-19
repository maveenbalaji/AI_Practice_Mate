import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/services/judge0_service.dart';

void main() {
  group('Judge0Service', () {
    late Judge0Service judge0Service;

    setUp(() {
      judge0Service = Judge0Service();
    });

    test('should have correct language ID mappings', () {
      expect(Judge0Service.languageIds['Python'], 71);
      expect(Judge0Service.languageIds['Java'], 62);
      expect(Judge0Service.languageIds['C++'], 54);
      expect(Judge0Service.languageIds['JavaScript'], 63);
      expect(Judge0Service.languageIds['C#'], 51);
    });

    test('should format output correctly for successful execution', () {
      final result = {
        'stdout': 'Hello, World!\n',
        'stderr': '',
        'compile_output': '',
        'status': {'description': 'Accepted'},
      };

      final output = judge0Service.getFormattedOutput(result);
      expect(output, 'Hello, World!\n');
    });

    test('should format output correctly for compilation error', () {
      final result = {
        'stdout': '',
        'stderr': '',
        'compile_output': 'error: expected \';\' at end of statement',
        'status': {'description': 'Compilation Error'},
      };

      final output = judge0Service.getFormattedOutput(result);
      expect(
        output,
        'Compilation Error:\nerror: expected \';\' at end of statement',
      );
    });

    test('should format output correctly for runtime error', () {
      final result = {
        'stdout': '',
        'stderr': 'Exception in thread "main" java.lang.NullPointerException',
        'compile_output': '',
        'status': {'description': 'Runtime Error'},
      };

      final output = judge0Service.getFormattedOutput(result);
      expect(
        output,
        'Runtime Error:\nException in thread "main" java.lang.NullPointerException',
      );
    });
  });
}
