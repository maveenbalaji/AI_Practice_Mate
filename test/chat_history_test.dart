import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/models/chat_history.dart';
import 'package:learn_ai/services/chat_history_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:uuid/uuid.dart';

// Mock implementation of PathProviderPlatform
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory _testDir = Directory.systemTemp.createTempSync(
    'chat_history_test',
  );

  @override
  Future<String?> getApplicationDocumentsPath() async {
    // Return a consistent temporary directory for testing
    return _testDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    // Return a consistent temporary directory for testing
    return _testDir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return _testDir.path;
  }

  // Cleanup method
  Future<void> cleanup() async {
    if (await _testDir.exists()) {
      await _testDir.delete(recursive: true);
    }
  }
}

void main() {
  group('Chat History System', () {
    late ChatHistoryService chatHistoryService;
    late String testUserId;
    late String testChatId;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() async {
      // Initialize the binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock path_provider with consistent directory
      mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;

      chatHistoryService = ChatHistoryService();
      testUserId = 'test_user_${Uuid().v4()}';
      testChatId = 'test_chat_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDown(() async {
      // Clean up test files
      await mockPathProvider.cleanup();
    });

    test('Start new chat session', () async {
      final chatHistory = await chatHistoryService.startNewChat(
        userId: testUserId,
        language: 'Python',
        topic: 'Loops',
      );

      expect(chatHistory, isNotNull);
      expect(chatHistory.language, 'Python');
      expect(chatHistory.topic, 'Loops');
      expect(chatHistory.messages, isEmpty);
    });

    test('Save and load chat history', () async {
      // Start a new chat
      final chatHistory = await chatHistoryService.startNewChat(
        userId: testUserId,
        language: 'Java',
        topic: 'Arrays',
      );

      // Add a message
      await chatHistoryService.addMessageToChat(
        userId: testUserId,
        chatId: chatHistory.chatId,
        role: 'user',
        type: 'text', // Add the required type parameter
        content: 'Hello, AI mentor!',
      );

      // Load the chat history
      final loadedChatHistory = await chatHistoryService.loadChatHistory(
        testUserId,
        chatHistory.chatId,
      );

      expect(loadedChatHistory, isNotNull);
      expect(loadedChatHistory!.messages, isNotEmpty);
      expect(loadedChatHistory.messages.length, 1);
      expect(loadedChatHistory.messages.first.role, 'user');
      expect(loadedChatHistory.messages.first.type, 'text'); // Check the type
      expect(loadedChatHistory.messages.first.content, 'Hello, AI mentor!');
    });

    test('Load all chat histories', () async {
      // Start multiple chat sessions with a delay to ensure unique timestamps
      final chat1 = await chatHistoryService.startNewChat(
        userId: testUserId,
        language: 'Python',
        topic: 'Loops',
      );

      // Add a small delay to ensure unique timestamps
      await Future.delayed(Duration(milliseconds: 10));

      final chat2 = await chatHistoryService.startNewChat(
        userId: testUserId,
        language: 'Java',
        topic: 'Arrays',
      );

      // Load all chat histories
      final chatHistories = await chatHistoryService.loadAllChatHistories(
        testUserId,
      );

      expect(chatHistories, isNotEmpty);
      expect(chatHistories.length, 2);
    });
  });
}
