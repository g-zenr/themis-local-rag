class Citation {
  final String document;
  final String section;

  const Citation({
    required this.document,
    required this.section,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      document: json['document'] as String,
      section: json['section'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document': document,
      'section': section,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Citation &&
        other.document == document &&
        other.section == section;
  }

  @override
  int get hashCode => Object.hash(document, section);

  @override
  String toString() => 'Citation(document: $document, section: $section)';
}
