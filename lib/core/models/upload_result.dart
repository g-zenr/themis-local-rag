class UploadResult {
  final String id;
  final String title;
  final int year;
  final int chunksIndexed;
  final String strategy;

  const UploadResult({
    required this.id,
    required this.title,
    required this.year,
    required this.chunksIndexed,
    required this.strategy,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      id: json['id'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      chunksIndexed: json['chunks_indexed'] as int,
      strategy: json['strategy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'chunks_indexed': chunksIndexed,
      'strategy': strategy,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadResult &&
        other.id == id &&
        other.title == title &&
        other.year == year &&
        other.chunksIndexed == chunksIndexed &&
        other.strategy == strategy;
  }

  @override
  int get hashCode => Object.hash(id, title, year, chunksIndexed, strategy);

  @override
  String toString() =>
      'UploadResult(id: $id, title: $title, year: $year, chunksIndexed: $chunksIndexed, strategy: $strategy)';
}
