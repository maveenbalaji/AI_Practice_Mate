import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/feedback_message.dart';
import '../models/test_case.dart';
import '../models/chart_session.dart';
import '../models/chat_history.dart';
import '../services/ai_service.dart';
import '../services/judge0_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/challenge_panel.dart';

class ChatScreen extends StatefulWidget {
  final String language;
  final String topic;
  final ChartSession? initialSession;
  final ChatHistory? initialChatHistory;

  const ChatScreen({
    super.key,
    required this.language,
    required this.topic,
    this.initialSession,
    this.initialChatHistory,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AIService _aiService = AIService();
  final Judge0Service _judge0Service = Judge0Service();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final List<FeedbackMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  Question? _currentQuestion;
  int _difficulty = 1; // Start with easy difficulty
  int _successCount = 0; // Track successful submissions
  String _selectedLanguage = '';

  // Add chat history tracking
  ChatHistory? _currentChatHistory;
  final String _userId =
      'user_123'; // In a real app, this would come from authentication

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.language; // Fixed to initial language

    if (widget.initialChatHistory != null) {
      _initializeFromChatHistory(widget.initialChatHistory!);
    } else if (widget.initialSession != null) {
      _initializeFromSession(widget.initialSession!);
    } else {
      _initializeChat();
    }
  }

  /// Initialize the chat from chat history
  Future<void> _initializeFromChatHistory(ChatHistory chatHistory) async {
    setState(() {
      _currentChatHistory = chatHistory;
    });

    // Add messages from chat history with delays to prevent race conditions
    for (int i = 0; i < chatHistory.messages.length; i++) {
      final message = chatHistory.messages[i];
      _addMessage(
        content: message.content,
        type: MessageType
            .text, // You might want to map this based on your message structure
        isUserMessage: message.role == 'user',
      );
      // Small delay between adding messages to prevent race conditions
      if (i < chatHistory.messages.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Add welcome message if no messages exist
    if (chatHistory.messages.isEmpty) {
      _addMessage(
        content:
            'Hello! I\'m CodeSensei, your AI coding mentor 👋\n\nWelcome back to "${chatHistory.topic}"!',
        type: MessageType.text,
        isUserMessage: false,
      );
    }

    // Generate first challenge if needed
    await _generateNextChallenge();
  }

  /// Initialize the chat from an existing session
  Future<void> _initializeFromSession(ChartSession session) async {
    // Add welcome message
    _addMessage(
      content:
          'Hello! I\'m CodeSensei, your AI coding mentor 👋\n\nWelcome back to "${session.chartTitle}"!',
      type: MessageType.text,
      isUserMessage: false,
    );

    // Restore messages from session history with delays to prevent race conditions
    for (int i = 0; i < session.history.length; i++) {
      final entry = session.history[i];
      _addMessage(
        content: entry.feedback,
        type: MessageType.text,
        isUserMessage: false,
      );
      // Small delay between adding messages to prevent race conditions
      if (i < session.history.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Set current question if available
    if (session.currentProblem.title.isNotEmpty) {
      // Convert CurrentProblem to Question
      final question = Question(
        id: session.currentProblem.problemId,
        title: session.currentProblem.title,
        description: session.currentProblem.description,
        topic: widget.topic,
        language: widget.language,
        difficulty: _getDifficultyLevel(session.currentProblem.difficulty),
        inputFormat: session.currentProblem.inputFormat,
        outputFormat: session.currentProblem.outputFormat,
        testCases: [
          TestCase(
            input: session.currentProblem.exampleInput,
            expectedOutput: session.currentProblem.exampleOutput,
          ),
        ],
      );

      setState(() {
        _currentQuestion = question;
        _difficulty = question.difficulty;
        _successCount = session.progress.correct ? 1 : 0;
      });
    } else {
      // Generate first challenge if no current problem
      await _generateNextChallenge();
    }
  }

  /// Initialize the chat with a welcome message and first challenge
  Future<void> _initializeChat() async {
    // Create a new chat history
    try {
      final newChatHistory = await _chatHistoryService.startNewChat(
        userId: _userId,
        language: widget.language,
        topic: widget.topic,
      );

      setState(() {
        _currentChatHistory = newChatHistory;
      });

      // Notify the sidebar to refresh (if we have a way to do this)
      // This would require passing a callback from TopicSelectionScreen to ChatScreen
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create new chat session')),
        );
      }
    }

    // Add welcome message
    _addMessage(
      content:
          'Hello! I\'m CodeSensei, your AI coding mentor 👋\n\nLet\'s practice ${widget.topic} in ${widget.language}!',
      type: MessageType.text,
      isUserMessage: false,
    );

    // Add motivational message with a small delay
    await Future.delayed(const Duration(milliseconds: 300));
    _addMessage(
      content:
          'I\'ll generate a challenge for you. Type your solution in the code editor on the right when you\'re ready!',
      type: MessageType.text,
      isUserMessage: false,
    );

    // Generate first challenge
    await _generateNextChallenge();
  }

  /// Convert difficulty string to int
  int _getDifficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 3;
      case 'hard':
        return 5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.language} - ${widget.topic}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _generateNextChallenge,
            tooltip: 'New Challenge',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left half: Chat area
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                // Loading indicator or chat input prompt
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('CodeSensei is thinking... 🤔'),
                      ],
                    ),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Chat with CodeSensei or use the code editor on the right',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Vertical divider
          const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
          // Right half: Challenge panel
          Expanded(
            flex: 1,
            child: ChallengePanel(
              initialLanguage: widget.language,
              onRunCode: _handleCodeRun,
              onSubmitCode: _handleCodeSubmit,
              onGetHint: _getHint,
              onNewChallenge: _generateNextChallenge,
              onReset: _resetCode,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a message bubble for chat
  Widget _buildMessageBubble(FeedbackMessage message) {
    final isUser = message.isUserMessage;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.school, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          // Message container
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.challenge) ...[
                    // Format challenge display with structured information
                    _buildChallengeDisplay(message.content),
                  ] else if (message.type == MessageType.code) ...[
                    // Enhanced code block with syntax highlighting
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Code content
                          Text(
                            message.content,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // "Run in interpreter" button for user code
                          if (isUser) ...[
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _runCodeInInterpreter(message.content),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Run in Interpreter'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (message.type == MessageType.celebration) ...[
                    Row(
                      children: [
                        const Icon(Icons.celebration, color: Colors.yellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.content,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Build structured challenge display
  Widget _buildChallengeDisplay(String content) {
    if (_currentQuestion == null) {
      return Text(content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Problem title with emoji
        Text(
          '🧩 ${_currentQuestion!.title}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        // Description
        Text(
          _currentQuestion!.description,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        // Input format
        if (_currentQuestion!.inputFormat != null) ...[
          const Text(
            'Input Format:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_currentQuestion!.inputFormat!),
          const SizedBox(height: 4),
        ],
        // Output format
        if (_currentQuestion!.outputFormat != null) ...[
          const Text(
            'Output Format:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_currentQuestion!.outputFormat!),
          const SizedBox(height: 4),
        ],
        // Example input
        if (_currentQuestion!.testCases != null &&
            _currentQuestion!.testCases!.isNotEmpty) ...[
          const Text(
            'Example Input:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_currentQuestion!.testCases!.first.input),
          ),
          const SizedBox(height: 4),
          // Example output
          const Text(
            'Example Output:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_currentQuestion!.testCases!.first.expectedOutput),
          ),
          const SizedBox(height: 4),
        ],
        // Difficulty
        Text(
          'Difficulty: ${_currentQuestion!.difficultyLevel}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Now, write your code in the editor on the right 👉',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  /// Save a message to the chat history file
  Future<void> _saveMessageToHistory(
    String content,
    String role,
    String type,
  ) async {
    if (_currentChatHistory == null) return;

    try {
      await _chatHistoryService.addMessageToChat(
        userId: _userId,
        chatId: _currentChatHistory!.chatId,
        role: role,
        type: type,
        content: content,
      );
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Failed to save message to history: $e');
    }
  }

  /// Add a message to the chat
  void _addMessage({
    required String content,
    required MessageType type,
    required bool isUserMessage,
    String? codeSnippet,
  }) {
    final message = FeedbackMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isUserMessage: isUserMessage,
      codeSnippet: codeSnippet,
    );

    setState(() {
      _messages.add(message);
    });

    // Map MessageType to string type for chat history
    String messageType = 'text';
    if (type == MessageType.challenge) {
      messageType = 'challenge';
    } else if (type == MessageType.code) {
      messageType = isUserMessage ? 'solution' : 'code';
    } else if (type == MessageType.celebration) {
      messageType = 'feedback';
    } else if (type == MessageType.feedback) {
      messageType = 'feedback';
    } else if (type == MessageType.hint) {
      messageType = 'hint';
    }

    // Save message to chat history (don't await to avoid blocking UI)
    _saveMessageToHistory(
      content,
      isUserMessage ? 'user' : 'assistant',
      messageType,
    );

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Generate the next challenge
  Future<void> _generateNextChallenge() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Adjust difficulty based on success count
      if (_successCount >= 5) {
        _difficulty = 5; // Hard
      } else if (_successCount >= 3) {
        _difficulty = 3; // Medium
      } else {
        _difficulty = 1; // Easy
      }

      final question = await _aiService.generateChallenge(
        topic: widget.topic,
        language: widget.language,
        difficulty: _difficulty,
      );

      if (question != null) {
        setState(() {
          _currentQuestion = question;
          // Set the topic and language for the question
          // We need to create a new Question object with the correct topic and language
          _currentQuestion = Question(
            id: question.id,
            title: question.title,
            description: question.description,
            topic: widget.topic,
            language: widget.language,
            difficulty: question.difficulty,
            inputFormat: question.inputFormat,
            outputFormat: question.outputFormat,
            testCases: question.testCases,
            hint: question.hint,
          );
        });

        // Add challenge to chat with structured format
        _addMessage(
          content: '', // Content will be built from _currentQuestion
          type: MessageType.challenge,
          isUserMessage: false,
        );
      } else {
        _addMessage(
          content:
              'Sorry, I couldn\'t generate a challenge right now. Please try again.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }
    } catch (e) {
      _addMessage(
        content:
            'An error occurred while generating the challenge. Please try again.',
        type: MessageType.text,
        isUserMessage: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle code submission from the challenge panel
  void _handleCodeSubmit(String code) {
    // Add user's code to chat
    _addMessage(content: code, type: MessageType.code, isUserMessage: true);

    // Process the code submission
    _processCodeSubmission(code, '');
  }

  /// Handle code run from the challenge panel
  void _handleCodeRun(String code) {
    // Add user's code to chat
    _addMessage(content: code, type: MessageType.code, isUserMessage: true);

    // Run the code
    _runCodeWithParams(code, '');
  }

  /// Reset code in the editor
  void _resetCode() {
    // This will be handled by the ChallengePanel widget
    // We just need to acknowledge the action in the chat
    _addMessage(
      content: 'Code editor has been reset.',
      type: MessageType.text,
      isUserMessage: false,
    );
  }

  /// Process code submission for evaluation
  Future<void> _processCodeSubmission(String code, String stdin) async {
    if (_isLoading || code.isEmpty) return;

    if (_currentQuestion == null) {
      _addMessage(
        content: 'No challenge available for evaluation.',
        type: MessageType.text,
        isUserMessage: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Execute code using Judge0 API first
      final executionResult = await _judge0Service.executeCode(
        sourceCode: code,
        language: _selectedLanguage, // Use fixed language
        stdin: stdin,
      );

      if (executionResult != null) {
        // Add execution result to chat
        final output = _judge0Service.getFormattedOutput(executionResult);
        _addMessage(
          content: 'Execution Result:\n$output',
          type: MessageType.text,
          isUserMessage: false,
        );
      } else {
        _addMessage(
          content: 'Failed to execute code. Proceeding with AI evaluation.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }

      // Continue with AI evaluation
      final result = await _aiService.evaluateCode(
        code: code,
        question: _currentQuestion!,
      );

      if (result != null) {
        final evaluation = result['evaluation'];
        final nextQuestion = result['next_question'];

        // Add evaluation result to chat
        _addMessage(
          content: evaluation.feedback,
          type: evaluation.status == 'PASS'
              ? MessageType.celebration
              : MessageType.feedback,
          isUserMessage: false,
        );

        // If user passed and we have a next question, show it immediately
        if (evaluation.status == 'PASS' && nextQuestion != null) {
          setState(() {
            _successCount++;
            _currentQuestion = nextQuestion;
            // Set the topic and language for the question
            _currentQuestion = Question(
              id: nextQuestion.id,
              title: nextQuestion.title,
              description: nextQuestion.description,
              topic: widget.topic,
              language: widget.language,
              difficulty: nextQuestion.difficulty,
              inputFormat: nextQuestion.inputFormat,
              outputFormat: nextQuestion.outputFormat,
              testCases: nextQuestion.testCases,
              hint: nextQuestion.hint,
            );
          });

          // Wait a bit before adding the next messages to ensure proper file operations
          await Future.delayed(const Duration(milliseconds: 500));
          _addMessage(
            content:
                '🎉 Great job! You nailed it. Here\'s your next challenge.',
            type: MessageType.text,
            isUserMessage: false,
          );
          await Future.delayed(const Duration(milliseconds: 500));

          // Add next challenge to chat with structured format
          _addMessage(
            content: '', // Content will be built from _currentQuestion
            type: MessageType.challenge,
            isUserMessage: false,
          );
        } else if (evaluation.status == 'PASS' && nextQuestion == null) {
          // User passed but no next question was provided, generate a new one
          setState(() {
            _successCount++;
          });

          // Wait a bit before adding the next messages to ensure proper file operations
          await Future.delayed(const Duration(milliseconds: 500));
          _addMessage(
            content:
                '🎉 Great job! You nailed it. Let\'s move to the next challenge.',
            type: MessageType.text,
            isUserMessage: false,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          await _generateNextChallenge();
        }
      } else {
        _addMessage(
          content:
              'Sorry, I couldn\'t evaluate your code right now. Please try again.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }
    } catch (e) {
      _addMessage(
        content:
            'An error occurred while evaluating your code. Please try again.',
        type: MessageType.text,
        isUserMessage: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get a hint for the current challenge
  Future<void> _getHint() async {
    if (_isLoading || _currentQuestion == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hint = await _aiService.getHint(_currentQuestion!);

      if (hint != null) {
        _addMessage(
          content: 'Hint: $hint',
          type: MessageType.hint,
          isUserMessage: false,
        );
      } else {
        _addMessage(
          content:
              'Sorry, I couldn\'t provide a hint right now. Please try again.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }
    } catch (e) {
      _addMessage(
        content: 'An error occurred while getting the hint. Please try again.',
        type: MessageType.text,
        isUserMessage: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Run code directly using Judge0 API without AI evaluation (deprecated - using new approach)
  Future<void> _runCode() async {
    // This method is now handled by the ChallengePanel widget
    // Keeping it for backward compatibility
  }

  /// Submit code for evaluation (deprecated - using new approach)
  Future<void> _submitCode() async {
    // This method is now handled by the ChallengePanel widget
    // Keeping it for backward compatibility
  }

  /// Run code in interpreter when user clicks the button in a code message
  Future<void> _runCodeInInterpreter(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Execute code using Judge0 API
      final executionResult = await _judge0Service.executeCode(
        sourceCode: code,
        language: _selectedLanguage, // Use fixed language
      );

      if (executionResult != null) {
        // Add execution result to chat
        final output = _judge0Service.getFormattedOutput(executionResult);
        _addMessage(
          content: 'Execution Result:\n$output',
          type: MessageType.text,
          isUserMessage: false,
        );
      } else {
        _addMessage(
          content:
              'Failed to execute code in interpreter. The API might be temporarily unavailable or quota limit exceeded. Please try again later.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }
    } catch (e) {
      _addMessage(
        content: 'Error executing code in interpreter: $e',
        type: MessageType.text,
        isUserMessage: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Run code with specific parameters
  Future<void> _runCodeWithParams(String code, String stdin) async {
    if (_isLoading || code.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Execute code using Judge0 API
      final executionResult = await _judge0Service.executeCode(
        sourceCode: code,
        language: _selectedLanguage, // Use fixed language
        stdin: stdin,
      );

      if (executionResult != null) {
        // Add execution result to chat
        final output = _judge0Service.getFormattedOutput(executionResult);
        _addMessage(
          content: 'Execution Result:\n$output',
          type: MessageType.text,
          isUserMessage: false,
        );
      } else {
        _addMessage(
          content:
              'Failed to execute code. The API might be temporarily unavailable or quota limit exceeded. Please try again later.',
          type: MessageType.text,
          isUserMessage: false,
        );
      }
    } catch (e) {
      _addMessage(
        content: 'An error occurred while executing your code: $e',
        type: MessageType.text,
        isUserMessage: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
