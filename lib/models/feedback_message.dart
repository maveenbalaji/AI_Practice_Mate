class FeedbackMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isUserMessage;
  final String? codeSnippet;

  FeedbackMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isUserMessage,
    this.codeSnippet,
  });

  factory FeedbackMessage.fromJson(Map<String, dynamic> json) {
    return FeedbackMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isUserMessage: json['is_user_message'] as bool,
      codeSnippet: json['code_snippet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['content'] = content;
    data['type'] = type.name;
    data['timestamp'] = timestamp.toIso8601String();
    data['is_user_message'] = isUserMessage;
    if (codeSnippet != null) data['code_snippet'] = codeSnippet;
    return data;
  }
}

enum MessageType { text, code, challenge, feedback, hint, celebration }
