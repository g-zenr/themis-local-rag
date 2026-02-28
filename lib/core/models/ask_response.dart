import 'package:template_app/core/models/citation.dart';

class AskResponse {
  final String answer;
  final List<Citation> citations;

  const AskResponse({
    required this.answer,
    required this.citations,
  });

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    return AskResponse(
      answer: json['answer'] as String,
      citations: (json['citations'] as List<dynamic>)
          .map((e) => Citation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'citations': citations.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AskResponse) return false;
    if (other.answer != answer) return false;
    if (other.citations.length != citations.length) return false;
    for (var i = 0; i < citations.length; i++) {
      if (other.citations[i] != citations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(answer, Object.hashAll(citations));

  @override
  String toString() =>
      'AskResponse(answer: $answer, citations: $citations)';
}
