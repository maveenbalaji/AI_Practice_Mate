// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatIndex _$ChatIndexFromJson(Map<String, dynamic> json) => ChatIndex(
  userId: json['user_id'] as String,
  chats: (json['chats'] as List<dynamic>)
      .map((e) => ChatInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatIndexToJson(ChatIndex instance) => <String, dynamic>{
  'user_id': instance.userId,
  'chats': instance.chats.map((e) => e.toJson()).toList(),
};

ChatInfo _$ChatInfoFromJson(Map<String, dynamic> json) => ChatInfo(
  chatId: json['chat_id'] as String,
  topic: json['topic'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$ChatInfoToJson(ChatInfo instance) => <String, dynamic>{
  'chat_id': instance.chatId,
  'topic': instance.topic,
  'created_at': instance.createdAt,
};
