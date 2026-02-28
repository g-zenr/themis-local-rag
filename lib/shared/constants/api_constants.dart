class ApiConstants {
  ApiConstants._();

  static const String serverUrlKey = 'server_url';
  static const String apiKeyKey = 'api_key';
  static const String useLocalAiKey = 'use_local_ai';
  static const String localModelPathKey = 'local_model_path';

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration streamingFirstTokenTimeout = Duration(seconds: 60);

  // Upload
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const List<String> supportedFileExtensions = ['pdf', 'txt'];

  // Question validation
  static const int minQuestionLength = 5;
  static const int maxQuestionLength = 2000;
  static const int charCountWarningThreshold = 1800;

  // Document title validation
  static const int minTitleLength = 2;
  static const int maxTitleLength = 200;

  // Year validation
  static const int minYear = 1900;
  static const int maxYear = 2100;

  // Health polling
  static const Duration healthCheckInterval = Duration(seconds: 30);

  // Default top-K
  static const int defaultTopK = 3;
}
