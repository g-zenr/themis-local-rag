import 'package:template_app/core/models/citation.dart';

class ChatMessage {
  final String role;
  final String content;
  final List<Citation> citations;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    this.citations = const [],
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => Citation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'citations': citations.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatMessage) return false;
    if (other.role != role) return false;
    if (other.content != content) return false;
    if (other.timestamp != timestamp) return false;
    if (other.citations.length != citations.length) return false;
    for (var i = 0; i < citations.length; i++) {
      if (other.citations[i] != citations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(role, content, Object.hashAll(citations), timestamp);

  @override
  String toString() =>
      'ChatMessage(role: $role, content: $content, citations: $citations, timestamp: $timestamp)';
}
