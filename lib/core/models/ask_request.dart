class AskRequest {
  final String question;
  final int topK;

  const AskRequest({
    required this.question,
    this.topK = 3,
  });

  factory AskRequest.fromJson(Map<String, dynamic> json) {
    return AskRequest(
      question: json['question'] as String,
      topK: (json['top_k'] as int?) ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'top_k': topK,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AskRequest &&
        other.question == question &&
        other.topK == topK;
  }

  @override
  int get hashCode => Object.hash(question, topK);

  @override
  String toString() => 'AskRequest(question: $question, topK: $topK)';
}
