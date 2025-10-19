import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/screens/topic_selection_screen.dart';
import 'package:learn_ai/screens/chat_screen.dart';

void main() {
  group('Workflow Tests', () {
    testWidgets('Language and topic selection flow works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: TopicSelectionScreen()));

      // Verify we're on the topic selection screen
      expect(find.text('Welcome to AI Practice Mate! 🎯'), findsOneWidget);
      expect(find.text('Choose Programming Language'), findsOneWidget);

      // Select Python as language
      await tester.tap(find.text('Python'));
      await tester.pump();

      // Verify topic selection is now visible
      expect(find.text('Choose Topic'), findsOneWidget);

      // Select a topic
      await tester.tap(find.text('Loops and Control Statements'));
      await tester.pump();

      // Verify start button is enabled by checking that it can be tapped
      final startButton = find.text('Start Learning with CodeSensei 🚀');
      expect(startButton, findsOneWidget);

      // Tap start button
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify we've navigated to the chat screen
      expect(
        find.text('Python - Loops and Control Statements'),
        findsOneWidget,
      );
    });

    testWidgets('Chat screen uses fixed language and has back button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            language: 'Python',
            topic: 'Loops and Control Statements',
          ),
        ),
      );

      // Verify the app bar shows the correct language and topic
      expect(
        find.text('Python - Loops and Control Statements'),
        findsOneWidget,
      );

      // Verify back button exists in app bar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
