import 'package:json_annotation/json_annotation.dart';

part 'chat_history.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatHistory {
  final String chatId;
  final String userId;
  final String createdAt;
  final String language;
  final String topic;
  final String title; // Add title field
  final List<Message> messages;

  ChatHistory({
    required this.chatId,
    required this.userId,
    required this.createdAt,
    required this.language,
    required this.topic,
    required this.title, // Add title parameter
    required this.messages,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$ChatHistoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Message {
  final String role;
  final String type; // Add type field
  final String timestamp;
  final String content;

  Message({
    required this.role,
    required this.type, // Add type parameter
    required this.timestamp,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
