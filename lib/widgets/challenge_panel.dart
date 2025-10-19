import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/cs.dart';

class ChallengePanel extends StatefulWidget {
  final String initialLanguage;
  final Function(String code) onRunCode;
  final Function(String code) onSubmitCode;
  final VoidCallback onGetHint;
  final VoidCallback onNewChallenge;
  final VoidCallback onReset;

  const ChallengePanel({
    super.key,
    required this.initialLanguage,
    required this.onRunCode,
    required this.onSubmitCode,
    required this.onGetHint,
    required this.onNewChallenge,
    required this.onReset,
  });

  @override
  State<ChallengePanel> createState() => _ChallengePanelState();
}

class _ChallengePanelState extends State<ChallengePanel> {
  late CodeController _codeController;
  String _selectedLanguage = '';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _codeController = CodeController(
      text: '',
      language: _getLanguageDefinition(_selectedLanguage),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Get the language definition for the selected language
  dynamic _getLanguageDefinition(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return python;
      case 'java':
        return java;
      case 'c++':
        return cpp;
      case 'javascript':
        return javascript;
      case 'c#':
        return cs; // Use 'cs' for C#
      default:
        return python; // Default to Python
    }
  }

  /// Reset the code editor
  void _resetCode() {
    _codeController.clear();
    widget.onReset();
  }

  /// Clear the code editor (for submit action)
  void _clearCode() {
    _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Code editor section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Run code without clearing the editor
                  widget.onRunCode(_codeController.text);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Submit code and clear the editor
                  widget.onSubmitCode(_codeController.text);
                  _clearCode();
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: widget.onGetHint,
                tooltip: 'Get Hint',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onNewChallenge,
                tooltip: 'New Challenge',
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                onPressed: _resetCode,
                tooltip: 'Reset Code',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
