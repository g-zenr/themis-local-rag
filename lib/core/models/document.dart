class Document {
  final String id;
  final String title;
  final int year;
  final int sectionCount;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.title,
    required this.year,
    required this.sectionCount,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      sectionCount: json['section_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'section_count': sectionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document &&
        other.id == id &&
        other.title == title &&
        other.year == year &&
        other.sectionCount == sectionCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, title, year, sectionCount, createdAt);

  @override
  String toString() =>
      'Document(id: $id, title: $title, year: $year, sectionCount: $sectionCount, createdAt: $createdAt)';
}
