import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/services/chat_history_service.dart';
import 'dart:io';
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
  group('Chat History Fix Test', () {
    late ChatHistoryService chatHistoryService;
    late String testUserId;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() async {
      // Initialize the binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock path_provider with consistent directory
      mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;

      chatHistoryService = ChatHistoryService();
      testUserId = 'test_user_${Uuid().v4()}';
    });

    tearDown(() async {
      // Clean up test files
      await mockPathProvider.cleanup();
    });

    test('Test chat history with proper type parameter', () async {
      print('Testing chat history service...');

      // Test creating a new chat
      final newChat = await chatHistoryService.startNewChat(
        userId: testUserId,
        language: 'Python',
        topic: 'Test Topic',
      );

      print('Created new chat: ${newChat.chatId}');

      // Test adding messages with the required type parameter
      await chatHistoryService.addMessageToChat(
        userId: testUserId,
        chatId: newChat.chatId,
        role: 'user',
        type: 'text', // Add the required type parameter
        content: 'Hello, AI mentor!',
      );

      print('Added user message');

      await chatHistoryService.addMessageToChat(
        userId: testUserId,
        chatId: newChat.chatId,
        role: 'assistant',
        type: 'text', // Add the required type parameter
        content: 'Hello! How can I help you today?',
      );

      print('Added assistant message');

      // Test loading the chat
      final loadedChat = await chatHistoryService.loadChatHistory(
        testUserId,
        newChat.chatId,
      );

      expect(loadedChat, isNotNull);
      if (loadedChat != null) {
        print('Loaded chat with ${loadedChat.messages.length} messages');
        for (var message in loadedChat.messages) {
          print('  ${message.role}: ${message.content}');
        }
        expect(loadedChat.messages.length, 2);
        expect(loadedChat.messages[0].role, 'user');
        expect(loadedChat.messages[0].type, 'text');
        expect(loadedChat.messages[0].content, 'Hello, AI mentor!');
        expect(loadedChat.messages[1].role, 'assistant');
        expect(loadedChat.messages[1].type, 'text');
        expect(
          loadedChat.messages[1].content,
          'Hello! How can I help you today?',
        );
      } else {
        fail('Failed to load chat');
      }

      // Test loading all chats
      final allChats = await chatHistoryService.loadAllChatHistories(
        testUserId,
      );
      print('Loaded ${allChats.length} chats for user');
      expect(allChats.length, 1);

      print('Test completed successfully!');
    });
  });
}
