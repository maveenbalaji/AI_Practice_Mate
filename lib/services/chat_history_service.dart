import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_history.dart';
import '../models/chat_index.dart';
import '../services/logger_service.dart';

class ChatHistoryService {
  static final Uuid _uuid = Uuid();

  // Map to track ongoing operations per chat to prevent race conditions
  final Map<String, Completer<void>> _locks = {};

  // Enhanced lock mechanism to prevent concurrent access to the same chat file
  Future<T> _withLock<T>(String key, Future<T> Function() operation) async {
    // Normalize the key to ensure consistency
    final normalizedKey = key.toLowerCase().trim();

    // Wait for any existing lock on this key
    final existingLock = _locks[normalizedKey];
    if (existingLock != null) {
      try {
        await existingLock.future;
      } catch (e) {
        // Ignore errors from previous operations
      }
    }

    // Create a new lock for this operation
    final completer = Completer<void>();
    _locks[normalizedKey] = completer;

    try {
      final result = await operation();
      completer.complete();
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      // Remove the lock
      _locks.remove(normalizedKey);
    }
  }

  /// Get the base directory for chat history
  Future<Directory> _getChatHistoryDirectory(String userId) async {
    final appDir =
        await getApplicationSupportDirectory(); // Use application support directory instead
    final chatHistoryDir = Directory('${appDir.path}/chat_history/$userId');
    if (!await chatHistoryDir.exists()) {
      await chatHistoryDir.create(recursive: true);
    }
    return chatHistoryDir;
  }

  /// Generate a unique chat ID with timestamp
  String _generateChatId() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'chat_$timestamp';
  }

  /// Generate a filename for a chat session
  String _generateChatFilename(String chatId) {
    return '$chatId.json';
  }

  /// Start a new chat session
  Future<ChatHistory> startNewChat({
    required String userId,
    required String language,
    required String topic,
  }) async {
    // Use a lock to prevent race conditions when starting new chats
    return _withLock('start_$userId', () async {
      try {
        final chatId = _generateChatId();
        // Use the same timestamp format as in chatId but with colons for createdAt
        final timestamp = DateTime.now().toIso8601String();

        // Create a descriptive title
        final title = '$language - $topic';

        final chatHistory = ChatHistory(
          chatId: chatId,
          userId: userId,
          createdAt: timestamp,
          language: language,
          topic: topic,
          title: title, // Add title
          messages: [],
        );

        // Save the new chat session
        await saveChatHistory(userId, chatHistory);

        // Update the index
        await _addToIndex(userId, chatHistory);

        AppLogger.info('Started new chat session: $chatId for user: $userId');
        return chatHistory;
      } catch (e) {
        AppLogger.error('Error starting new chat: $e');
        rethrow;
      }
    });
  }

  /// Save a chat history to a JSON file using atomic writes
  Future<void> saveChatHistory(String userId, ChatHistory chatHistory) async {
    // Use a lock to prevent concurrent writes to the same file
    return _withLock('save_${userId}_${chatHistory.chatId}', () async {
      try {
        final chatHistoryDir = await _getChatHistoryDirectory(userId);
        final filename = _generateChatFilename(chatHistory.chatId);
        final filePath = '${chatHistoryDir.path}/$filename';

        // Save the chat history data to a JSON file with proper encoding
        final jsonString = jsonEncode(chatHistory.toJson());

        // Add debugging information
        AppLogger.info('Saving chat history to: $filePath');
        AppLogger.info('JSON string length: ${jsonString.length}');
        AppLogger.info(
          'First 100 characters: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}',
        );

        // Write to a temporary file first for atomic operation
        final tempPath = '$filePath.tmp';
        final tempFile = File(tempPath);

        try {
          // Write to temp file
          await tempFile.writeAsString(jsonString, mode: FileMode.write);

          // Delete the old file if it exists
          final file = File(filePath);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (deleteError) {
              AppLogger.warning('Error deleting old file: $deleteError');
              // If we can't delete, try to rename the old file
              try {
                final backupPath =
                    '$filePath.bak_${DateTime.now().millisecondsSinceEpoch}';
                await file.rename(backupPath);
                AppLogger.info('Renamed old file to backup: $backupPath');
              } catch (renameError) {
                AppLogger.error('Error backing up old file: $renameError');
              }
            }
          }

          // Rename the temp file to the target path
          try {
            await tempFile.rename(filePath);
          } catch (renameError) {
            AppLogger.error('Error renaming temp file: $renameError');
            // Try to copy and then delete if rename fails
            try {
              await tempFile.copy(filePath);
              await tempFile.delete();
            } catch (copyError) {
              AppLogger.error('Error copying temp file: $copyError');
              rethrow;
            }
          }
        } catch (writeError) {
          // Clean up temp file if it exists
          try {
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (cleanupError) {
            AppLogger.warning('Error cleaning up temp file: $cleanupError');
          }
          rethrow;
        }

        AppLogger.info('Saved chat history ${chatHistory.chatId} to $filename');
      } catch (e, stackTrace) {
        AppLogger.error('Error saving chat history: $e', e, stackTrace);
        rethrow;
      }
    });
  }

  /// Add a message to a chat session
  Future<void> addMessageToChat({
    required String userId,
    required String chatId,
    required String role,
    required String type,
    required String content,
  }) async {
    // Use a lock to prevent race conditions when multiple messages are added quickly
    return _withLock('chat_${userId}_$chatId', () async {
      try {
        final chatHistory = await loadChatHistory(userId, chatId);
        if (chatHistory == null) {
          // Check if there's a corrupted version of this chat
          final chatHistoryDir = await _getChatHistoryDirectory(userId);
          final filename = _generateChatFilename(chatId);
          final corruptedFilePath =
              '${chatHistoryDir.path}/${chatId}_CORRUPTED_';

          // Look for any corrupted files with this chat ID
          final dir = chatHistoryDir;
          if (await dir.exists()) {
            final files = dir.listSync();
            for (final file in files) {
              if (file.path.contains(corruptedFilePath)) {
                AppLogger.info(
                  'Found corrupted version of chat $chatId at: ${file.path}',
                );
                // Try to restore from the corrupted file
                try {
                  final corruptedFile = File(file.path);
                  final corruptedContent = await corruptedFile.readAsString();

                  // Try to parse the JSON
                  final json = jsonDecode(corruptedContent);
                  final restoredChat = ChatHistory.fromJson(json);

                  // Save the restored chat
                  await saveChatHistory(userId, restoredChat);
                  AppLogger.info('Restored chat $chatId from corrupted file');

                  // Now try to add the message again
                  final message = Message(
                    role: role,
                    type: type,
                    timestamp: DateTime.now().toIso8601String(),
                    content: content,
                  );

                  restoredChat.messages.add(message);
                  await saveChatHistory(userId, restoredChat);
                  AppLogger.info(
                    'Added message to restored chat $chatId for user $userId',
                  );
                  return;
                } catch (restoreError) {
                  AppLogger.error(
                    'Failed to restore chat $chatId from corrupted file: $restoreError',
                  );
                }
              }
            }
          }

          throw Exception('Chat session not found: $chatId');
        }

        final message = Message(
          role: role,
          type: type,
          timestamp: DateTime.now().toIso8601String(),
          content: content,
        );

        chatHistory.messages.add(message);
        await saveChatHistory(userId, chatHistory);

        AppLogger.info('Added message to chat $chatId for user $userId');
      } catch (e) {
        AppLogger.error('Error adding message to chat: $e');
        rethrow;
      }
    });
  }

  /// Load a chat history from a JSON file
  Future<ChatHistory?> loadChatHistory(String userId, String chatId) async {
    try {
      final chatHistoryDir = await _getChatHistoryDirectory(userId);
      final filename = _generateChatFilename(chatId);
      final filePath = '${chatHistoryDir.path}/$filename';
      final file = File(filePath);

      AppLogger.info('Attempting to load chat history from: $filePath');
      AppLogger.info('File exists: ${await file.exists()}');

      if (await file.exists()) {
        final content = await file.readAsString();
        AppLogger.info('File content length: ${content.length}');
        AppLogger.info(
          'First 100 characters: ${content.substring(0, content.length > 100 ? 100 : content.length)}',
        );

        // Add validation to ensure we have valid JSON
        if (content.trim().isEmpty) {
          AppLogger.error('Chat history file is empty: $filename');
          return null;
        }

        // Try to parse the JSON
        final json = jsonDecode(content);
        return ChatHistory.fromJson(json);
      } else {
        AppLogger.warning('Chat history file does not exist: $filePath');
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading chat history: $e', e, stackTrace);
      // If we get a FormatException, try to recover by creating a backup of the corrupted file
      if (e is FormatException) {
        AppLogger.error(
          'JSON format error in chat history file. Attempting to recover...',
        );
        try {
          final chatHistoryDir = await _getChatHistoryDirectory(userId);
          final filename = _generateChatFilename(chatId);
          final filePath = '${chatHistoryDir.path}/$filename';
          final corruptedFilePath =
              '${chatHistoryDir.path}/${chatId}_CORRUPTED_${DateTime.now().millisecondsSinceEpoch}.json';

          // Rename the corrupted file
          final file = File(filePath);
          if (await file.exists()) {
            await file.rename(corruptedFilePath);
            AppLogger.info('Renamed corrupted file to: $corruptedFilePath');
          }
        } catch (renameError) {
          AppLogger.error('Failed to rename corrupted file: $renameError');
        }
      }
      return null;
    }
  }

  /// Load all chat histories for a user
  Future<List<ChatHistory>> loadAllChatHistories(String userId) async {
    try {
      final chatHistoryDir = await _getChatHistoryDirectory(userId);
      final List<ChatHistory> chatHistories = [];

      // Check if directory exists
      if (!await chatHistoryDir.exists()) {
        return chatHistories;
      }

      // List all JSON files in the user's chat history directory
      final files = chatHistoryDir.listSync().where((file) {
        return file.path.endsWith('.json') &&
            !file.path.endsWith('chat_index.json');
      });

      // Load each chat history file
      for (final file in files) {
        try {
          final content = await File(file.path).readAsString();
          // Skip empty files
          if (content.trim().isEmpty) {
            AppLogger.warning('Skipping empty chat history file: ${file.path}');
            continue;
          }

          final json = jsonDecode(content);
          final chatHistory = ChatHistory.fromJson(json);
          chatHistories.add(chatHistory);
        } catch (e) {
          AppLogger.error('Error loading chat history file ${file.path}: $e');
          // If we get a FormatException, try to recover by creating a backup of the corrupted file
          if (e is FormatException) {
            try {
              final corruptedFilePath =
                  '${file.path}_CORRUPTED_${DateTime.now().millisecondsSinceEpoch}';
              await file.rename(corruptedFilePath);
              AppLogger.info('Renamed corrupted file to: $corruptedFilePath');
            } catch (renameError) {
              AppLogger.error('Failed to rename corrupted file: $renameError');
            }
          }
          // Continue with other files even if one fails
        }
      }

      return chatHistories;
    } catch (e) {
      AppLogger.error('Error loading chat histories: $e');
      return [];
    }
  }

  /// Delete a chat history
  Future<void> deleteChatHistory(String userId, String chatId) async {
    // Use a lock to prevent race conditions
    return _withLock('delete_${userId}_$chatId', () async {
      try {
        final chatHistoryDir = await _getChatHistoryDirectory(userId);
        final filename = _generateChatFilename(chatId);
        final filePath = '${chatHistoryDir.path}/$filename';
        final file = File(filePath);

        if (await file.exists()) {
          try {
            await file.delete();
            await _removeFromIndex(userId, chatId);
            AppLogger.info('Deleted chat history $chatId for user $userId');
          } catch (deleteError) {
            // If we can't delete the file, log the error
            AppLogger.error('Error deleting chat history file: $deleteError');
            // Try to rename the file instead to prevent further issues
            try {
              final corruptedPath =
                  '${filePath}_CORRUPTED_${DateTime.now().millisecondsSinceEpoch}';
              await file.rename(corruptedPath);
              AppLogger.info('Renamed problematic file to: $corruptedPath');
              await _removeFromIndex(userId, chatId);
            } catch (renameError) {
              AppLogger.error('Error renaming problematic file: $renameError');
            }
          }
        } else {
          // File doesn't exist, but we should still remove it from the index
          await _removeFromIndex(userId, chatId);
          AppLogger.info(
            'Chat history file $chatId did not exist, removed from index for user $userId',
          );
        }
      } catch (e) {
        AppLogger.error('Error deleting chat history: $e');
      }
    });
  }

  /// Clear all chat histories for a user
  Future<void> clearAllChatHistories(String userId) async {
    try {
      final chatHistoryDir = await _getChatHistoryDirectory(userId);
      if (await chatHistoryDir.exists()) {
        // Instead of deleting the entire directory, delete individual files
        final files = chatHistoryDir.listSync();
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            AppLogger.error('Error deleting file ${file.path}: $e');
            // Try to rename the file instead to prevent further issues
            try {
              final corruptedPath =
                  '${file.path}_CORRUPTED_${DateTime.now().millisecondsSinceEpoch}';
              await file.rename(corruptedPath);
              AppLogger.info('Renamed problematic file to: $corruptedPath');
            } catch (renameError) {
              AppLogger.error('Error renaming problematic file: $renameError');
            }
            // Continue with other files even if one fails
          }
        }
        AppLogger.info('Cleared all chat histories for user $userId');
      }
    } catch (e) {
      AppLogger.error('Error clearing chat histories: $e');
    }
  }

  /// Add chat to index
  Future<void> _addToIndex(String userId, ChatHistory chatHistory) async {
    // Use a lock to prevent concurrent writes to the index file
    return _withLock('index_$userId', () async {
      try {
        final indexFile = await _getIndexFile(userId);
        ChatIndex? index;

        // Load existing index or create new one
        if (await indexFile.exists()) {
          final content = await indexFile.readAsString();
          final json = jsonDecode(content);
          index = ChatIndex.fromJson(json);
        } else {
          index = ChatIndex(userId: userId, chats: []);
        }

        // Add new chat info
        final chatInfo = ChatInfo(
          chatId: chatHistory.chatId,
          topic: chatHistory
              .title, // Use title instead of topic for better display
          createdAt: chatHistory.createdAt,
        );

        // Check if chat already exists in index
        final existingIndex = index.chats.indexWhere(
          (chat) => chat.chatId == chatHistory.chatId,
        );
        if (existingIndex != -1) {
          // Update existing chat info
          index.chats[existingIndex] = chatInfo;
        } else {
          // Add new chat info
          index.chats.add(chatInfo);
        }

        // Save updated index using atomic write
        final jsonString = jsonEncode(index.toJson());
        final tempPath = '${indexFile.path}.tmp';
        final tempFile = File(tempPath);

        try {
          // Write to temp file
          await tempFile.writeAsString(jsonString, mode: FileMode.write);

          // Delete the old file if it exists
          if (await indexFile.exists()) {
            try {
              await indexFile.delete();
            } catch (deleteError) {
              AppLogger.warning('Error deleting old index file: $deleteError');
            }
          }

          // Rename the temp file to the target path
          await tempFile.rename(indexFile.path);
        } catch (writeError) {
          // Clean up temp file if it exists
          try {
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (cleanupError) {
            AppLogger.warning(
              'Error cleaning up temp index file: $cleanupError',
            );
          }
          rethrow;
        }
      } catch (e) {
        AppLogger.error('Error adding chat to index: $e');
      }
    });
  }

  /// Remove chat from index
  Future<void> _removeFromIndex(String userId, String chatId) async {
    // Use a lock to prevent concurrent writes to the index file
    return _withLock('index_$userId', () async {
      try {
        final indexFile = await _getIndexFile(userId);

        if (await indexFile.exists()) {
          final content = await indexFile.readAsString();
          final json = jsonDecode(content);
          final index = ChatIndex.fromJson(json);

          // Remove chat from index
          index.chats.removeWhere((chat) => chat.chatId == chatId);

          // Save updated index using atomic write
          final jsonString = jsonEncode(index.toJson());
          final tempPath = '${indexFile.path}.tmp';
          final tempFile = File(tempPath);

          try {
            // Write to temp file
            await tempFile.writeAsString(jsonString, mode: FileMode.write);

            // Delete the old file if it exists
            if (await indexFile.exists()) {
              try {
                await indexFile.delete();
              } catch (deleteError) {
                AppLogger.warning(
                  'Error deleting old index file: $deleteError',
                );
              }
            }

            // Rename the temp file to the target path
            await tempFile.rename(indexFile.path);
          } catch (writeError) {
            // Clean up temp file if it exists
            try {
              if (await tempFile.exists()) {
                await tempFile.delete();
              }
            } catch (cleanupError) {
              AppLogger.warning(
                'Error cleaning up temp index file: $cleanupError',
              );
            }
            rethrow;
          }
        }
      } catch (e) {
        AppLogger.error('Error removing chat from index: $e');
      }
    });
  }

  /// Get the index file for a user
  Future<File> _getIndexFile(String userId) async {
    final chatHistoryDir = await _getChatHistoryDirectory(userId);
    return File('${chatHistoryDir.path}/chat_index.json');
  }

  /// Load chat index for a user
  Future<ChatIndex?> loadChatIndex(String userId) async {
    try {
      final indexFile = await _getIndexFile(userId);

      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content);
        return ChatIndex.fromJson(json);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error loading chat index: $e');
      return null;
    }
  }
}
