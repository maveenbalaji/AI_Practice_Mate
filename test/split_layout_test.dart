import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/screens/chat_screen.dart';

void main() {
  group('Split Layout Tests', () {
    testWidgets(
      'Chat screen shows split layout with chat and challenge panels',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChatScreen(
              language: 'Python',
              topic: 'Loops and Control Statements',
            ),
          ),
        );

        // Verify we're on the chat screen
        expect(
          find.text('Python - Loops and Control Statements'),
          findsOneWidget,
        );

        // Verify the split layout exists
        expect(find.byType(Row), findsOneWidget);

        // Verify left panel (chat area) exists
        expect(
          find.text('Chat with CodeSensei or use the code editor on the right'),
          findsOneWidget,
        );

        // Verify right panel (challenge panel) exists
        expect(
          find.text(
            'No challenge available. Generate a new challenge to get started.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Challenge panel has action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatScreen(
              language: 'Python',
              topic: 'Loops and Control Statements',
            ),
          ),
        ),
      );

      // Verify action buttons exist (using different approach to avoid conflicts)
      expect(find.text('Run Code'), findsWidgets);
      expect(find.text('Submit Code'), findsWidgets);
      expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
      expect(find.byIcon(Icons.refresh), findsWidgets);
      expect(find.byIcon(Icons.restart_alt), findsWidgets);
    });
  });
}
