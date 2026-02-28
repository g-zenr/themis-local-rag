class HealthStatus {
  final String status;
  final String database;
  final bool modelLoaded;
  final int totalChunks;
  final int indexedChunks;

  const HealthStatus({
    required this.status,
    required this.database,
    required this.modelLoaded,
    required this.totalChunks,
    required this.indexedChunks,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String,
      database: json['database'] as String,
      modelLoaded: json['model_loaded'] as bool,
      totalChunks: json['total_chunks'] as int,
      indexedChunks: json['indexed_chunks'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'database': database,
      'model_loaded': modelLoaded,
      'total_chunks': totalChunks,
      'indexed_chunks': indexedChunks,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthStatus &&
        other.status == status &&
        other.database == database &&
        other.modelLoaded == modelLoaded &&
        other.totalChunks == totalChunks &&
        other.indexedChunks == indexedChunks;
  }

  @override
  int get hashCode => Object.hash(
        status,
        database,
        modelLoaded,
        totalChunks,
        indexedChunks,
      );

  @override
  String toString() =>
      'HealthStatus(status: $status, database: $database, modelLoaded: $modelLoaded, totalChunks: $totalChunks, indexedChunks: $indexedChunks)';
}
