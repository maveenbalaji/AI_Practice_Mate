import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/cs.dart';

class ChatInputArea extends StatefulWidget {
  final String initialLanguage;
  final Function(String code, String language, String stdin) onCodeSubmit;
  final Function(String code, String language, String stdin) onCodeRun;
  final VoidCallback onGetHint;
  final VoidCallback onNewChallenge;

  const ChatInputArea({
    super.key,
    required this.initialLanguage,
    required this.onCodeSubmit,
    required this.onCodeRun,
    required this.onGetHint,
    required this.onNewChallenge,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  late CodeController _codeController;
  String _selectedLanguage = '';
  bool _isInCodeMode = true; // Toggle between chat and code mode

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode toggle (without language selector as per requirements)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Mode toggle
              ToggleButtons(
                isSelected: [_isInCodeMode, !_isInCodeMode],
                onPressed: (int index) {
                  setState(() {
                    _isInCodeMode = index == 0;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Code'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Content area (code editor or chat input)
        if (_isInCodeMode) ...[
          // Code editor (fixed to initial language)
          Padding(
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
                // Enable tab indentation and handle changes
                onChanged: (text) {
                  // Handle text changes for auto-indentation if needed
                },
                maxLines: 10,
                minLines: 5,
              ),
            ),
          ),
        ] else ...[
          // Standard chat input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isInCodeMode
                      ? () {
                          widget.onCodeSubmit(
                            _codeController.text,
                            _selectedLanguage,
                            '', // Empty stdin
                          );
                          _codeController.clear();
                        }
                      : null, // Disable when in chat mode
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: _isInCodeMode
                    ? () {
                        widget.onCodeRun(
                          _codeController.text,
                          _selectedLanguage,
                          '', // Empty stdin
                        );
                      }
                    : null, // Disable when in chat mode
                tooltip: 'Run Code',
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
              // Back button to return to topic selection
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: 'Back to Language/Topic Selection',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
