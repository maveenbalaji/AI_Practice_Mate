import 'package:flutter/material.dart';
import '../models/language.dart';
import 'chat_screen.dart';
import '../widgets/chat_history_sidebar.dart';
import '../widgets/searchable_language_dropdown.dart';
import '../services/chat_history_service.dart';
import '../models/chat_history.dart';
import '../services/ai_service.dart';

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  // Selected programming language
  Language? _selectedLanguage;

  // Selected topic
  String? _selectedTopic;

  // Available topics for the selected language
  List<String> _availableTopics = [];

  // Loading state for topics
  bool _isLoadingTopics = false;

  // Programming languages available with TIOBE ratings
  final List<Language> _languages = [
    Language(name: 'Python', rating: 24.45, judge0Id: 71),
    Language(name: 'C', rating: 9.29, judge0Id: 50),
    Language(name: 'C++', rating: 8.84, judge0Id: 54),
    Language(name: 'Java', rating: 8.35, judge0Id: 62),
    Language(name: 'C#', rating: 6.94, judge0Id: 51),
    Language(name: 'JavaScript', rating: 3.41, judge0Id: 63),
    Language(name: 'Visual Basic', rating: 3.22),
    Language(name: 'Go', rating: 1.92, judge0Id: 60),
    Language(name: 'Delphi/Object Pascal', rating: 1.86),
    Language(name: 'SQL', rating: 1.77),
    Language(name: 'Fortran', rating: 1.70),
    Language(name: 'Perl', rating: 1.66, judge0Id: 58),
    Language(name: 'R', rating: 1.52),
    Language(name: 'PHP', rating: 1.38, judge0Id: 68),
    Language(name: 'Assembly language', rating: 1.20),
    Language(name: 'Rust', rating: 1.19),
    Language(name: 'MATLAB', rating: 1.16),
    Language(name: 'Scratch', rating: 1.15),
    Language(name: 'Ada', rating: 0.98),
    Language(name: 'Kotlin', rating: 0.98, judge0Id: 78),
    Language(name: 'Classic Visual Basic', rating: 0.97),
    Language(name: 'Swift', rating: 0.94, judge0Id: 83),
    Language(name: 'COBOL', rating: 0.86),
    Language(name: 'Prolog', rating: 0.80),
    Language(name: 'Ruby', rating: 0.77, judge0Id: 72),
    Language(name: 'SAS', rating: 0.65),
    Language(name: 'Dart', rating: 0.62),
    Language(name: 'Lisp', rating: 0.55),
    Language(name: '(Visual) FoxPro', rating: 0.47),
    Language(name: 'Julia', rating: 0.46),
    Language(name: 'Objective-C', rating: 0.46),
    Language(name: 'Haskell', rating: 0.45, judge0Id: 61),
    Language(name: 'Lua', rating: 0.38, judge0Id: 64),
    Language(name: 'Scala', rating: 0.36),
    Language(name: 'TypeScript', rating: 0.31),
    Language(name: 'PL/SQL', rating: 0.26),
    Language(name: 'VBScript', rating: 0.24),
    Language(name: 'GAMS', rating: 0.24),
    Language(name: 'ABAP', rating: 0.23),
    Language(name: 'Solidity', rating: 0.20),
    Language(name: 'Elixir', rating: 0.19),
    Language(name: 'V', rating: 0.17),
    Language(name: 'Zig', rating: 0.17),
    Language(name: 'Bash', rating: 0.16, judge0Id: 46),
    Language(name: 'ML', rating: 0.16),
    Language(name: 'Transact-SQL', rating: 0.15),
    Language(name: 'PowerShell', rating: 0.15),
    Language(name: 'Erlang', rating: 0.15, judge0Id: 45),
    Language(name: 'RPG', rating: 0.14),
    Language(name: 'Ladder Logic', rating: 0.14),
  ];

  // User ID (in a real app, this would come from authentication)
  final String _userId = 'user_123';

  // AI Service for fetching topics
  final AIService _aiService = AIService();

  // Keep a reference to the sidebar for refreshing
  final GlobalKey<ChatHistorySidebarState> _sidebarKey =
      GlobalKey<ChatHistorySidebarState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Practice Mate'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Chat history sidebar
          ChatHistorySidebar(
            key: _sidebarKey, // Add key to access the sidebar state
            userId: _userId,
            onChatSelected: _loadChatSession,
            onNewChat: _startNewChat,
            onRefresh: _refreshSidebar, // Add refresh callback
          ),
          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to AI Practice Mate! 🎯',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a programming language and topic to get started with your coding journey.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Choose Programming Language',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Searchable language dropdown
                  SearchableLanguageDropdown(
                    selectedLanguage: _selectedLanguage,
                    languages: _languages,
                    onChanged: (language) async {
                      setState(() {
                        _selectedLanguage = language;
                        _selectedTopic =
                            null; // Reset topic when language changes
                        _availableTopics =
                            []; // Clear topics when language changes
                      });

                      // Fetch topics for the selected language
                      if (language != null) {
                        await _fetchTopicsForLanguage(language.name);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  if (_selectedLanguage != null) ...[
                    const Text(
                      'Choose Topic',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingTopics) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      const Text('Fetching topics from AI...'),
                    ] else ...[
                      // Topic selection chips
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _availableTopics.map((topic) {
                              return ChoiceChip(
                                label: Text(topic),
                                selected: _selectedTopic == topic,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTopic = selected ? topic : null;
                                  });
                                },
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                backgroundColor: Colors.grey[200],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedLanguage != null && _selectedTopic != null)
                          ? _startLearning
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Learning with CodeSensei 🚀',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch topics for the selected language from the AI service
  Future<void> _fetchTopicsForLanguage(String language) async {
    setState(() {
      _isLoadingTopics = true;
    });

    try {
      final topics = await _aiService.fetchTopicsForLanguage(language);
      setState(() {
        _availableTopics = topics;
        _isLoadingTopics = false;
      });
    } catch (e) {
      print('Error fetching topics: $e');
      setState(() {
        _availableTopics = ['Failed to fetch topics. Please try again.'];
        _isLoadingTopics = false;
      });
    }
  }

  /// Navigate to chat screen with selected language and topic
  void _startLearning() {
    if (_selectedLanguage != null && _selectedTopic != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            language: _selectedLanguage!.name,
            topic: _selectedTopic!,
          ),
        ),
      ).then((_) {
        // Refresh the sidebar when returning from chat screen
        _refreshSidebar();
      });
    }
  }

  /// Start a new chat session
  void _startNewChat() {
    // Reset selections to show the language/topic selection UI
    setState(() {
      _selectedLanguage = null;
      _selectedTopic = null;
      _availableTopics = [];
    });
  }

  /// Refresh the chat history sidebar
  void _refreshSidebar() {
    if (_sidebarKey.currentState != null) {
      _sidebarKey.currentState!.refreshChatHistories();
    }
  }

  /// Load an existing chat session
  void _loadChatSession(ChatHistory chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          language: chat.language,
          topic: chat.topic,
          initialChatHistory: chat,
        ),
      ),
    ).then((_) {
      // Refresh the sidebar when returning from chat screen
      _refreshSidebar();
    });
  }
}
