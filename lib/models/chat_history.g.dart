// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatHistory _$ChatHistoryFromJson(Map<String, dynamic> json) => ChatHistory(
  chatId: json['chat_id'] as String,
  userId: json['user_id'] as String,
  createdAt: json['created_at'] as String,
  language: json['language'] as String,
  topic: json['topic'] as String,
  title: json['title'] as String, // Add title field
  messages: (json['messages'] as List<dynamic>)
      .map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatHistoryToJson(ChatHistory instance) =>
    <String, dynamic>{
      'chat_id': instance.chatId,
      'user_id': instance.userId,
      'created_at': instance.createdAt,
      'language': instance.language,
      'topic': instance.topic,
      'title': instance.title, // Add title field
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  role: json['role'] as String,
  type: json['type'] as String, // Add type field
  timestamp: json['timestamp'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'role': instance.role,
  'type': instance.type, // Add type field
  'timestamp': instance.timestamp,
  'content': instance.content,
};
