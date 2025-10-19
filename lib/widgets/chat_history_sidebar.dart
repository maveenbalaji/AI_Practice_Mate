import 'package:flutter/material.dart';
import '../models/chat_history.dart';
import '../services/chat_history_service.dart';

class ChatHistorySidebar extends StatefulWidget {
  final String userId;
  final Function(ChatHistory) onChatSelected;
  final Function() onNewChat;
  final Function() onRefresh; // Add refresh callback

  const ChatHistorySidebar({
    super.key,
    required this.userId,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onRefresh, // Add refresh callback
  });

  @override
  State<ChatHistorySidebar> createState() => ChatHistorySidebarState(); // Make public
}

// Make the class public by removing the underscore
class ChatHistorySidebarState extends State<ChatHistorySidebar> {
  late ChatHistoryService _chatHistoryService;
  List<ChatHistory> _chatHistories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatHistoryService = ChatHistoryService();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final histories = await _chatHistoryService.loadAllChatHistories(
        widget.userId,
      );
      // Sort by created date (newest first)
      histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _chatHistories = histories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chat history')),
        );
      }
    }
  }

  // Add public method to refresh chat histories
  Future<void> refreshChatHistories() async {
    await _loadChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Header with title and new chat button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chat History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: widget.onNewChat,
                  tooltip: 'New Chat',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Chat history list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chatHistories.isEmpty
                ? const Center(
                    child: Text(
                      'No chat history yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatHistories.length,
                    itemBuilder: (context, index) {
                      final chat = _chatHistories[index];
                      return ChatHistoryItem(
                        chat: chat,
                        onTap: () => widget.onChatSelected(chat),
                        onDelete: () => _deleteChat(chat.chatId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      await _chatHistoryService.deleteChatHistory(widget.userId, chatId);
      await _loadChatHistories(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete chat')));
      }
    }
  }
}

class ChatHistoryItem extends StatelessWidget {
  final ChatHistory chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatHistoryItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(chat.createdAt);
    final formattedDate =
        '${createdAt.month}/${createdAt.day}/${createdAt.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          '${chat.language} - ${chat.topic}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formattedDate),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
