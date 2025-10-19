import 'package:json_annotation/json_annotation.dart';

part 'chat_index.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatIndex {
  final String userId;
  final List<ChatInfo> chats;

  ChatIndex({required this.userId, required this.chats});

  factory ChatIndex.fromJson(Map<String, dynamic> json) =>
      _$ChatIndexFromJson(json);

  Map<String, dynamic> toJson() => _$ChatIndexToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatInfo {
  final String chatId;
  final String topic;
  final String createdAt;

  ChatInfo({
    required this.chatId,
    required this.topic,
    required this.createdAt,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatInfoToJson(this);
}
