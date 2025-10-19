import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  try {
    // Get the application support directory
    final appDir = await getApplicationSupportDirectory();
    final chatHistoryDir = Directory('${appDir.path}/chat_history/user_123');

    if (await chatHistoryDir.exists()) {
      // List all files in the directory
      final files = chatHistoryDir.listSync();

      // Delete all files (corrupted ones will be removed)
      for (final file in files) {
        try {
          if (await file.exists()) {
            await file.delete();
            print('Deleted: ${file.path}');
          }
        } catch (e) {
          print('Error deleting ${file.path}: $e');
        }
      }

      // Delete the directory itself
      await chatHistoryDir.delete(recursive: true);
      print('Chat history directory cleaned up successfully');
    } else {
      print('Chat history directory does not exist');
    }
  } catch (e) {
    print('Error cleaning up chat history: $e');
  }
}
