class ServerConfig {
  final String serverUrl;
  final String apiKey;

  const ServerConfig({
    required this.serverUrl,
    required this.apiKey,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['server_url'] as String,
      apiKey: json['api_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_url': serverUrl,
      'api_key': apiKey,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.serverUrl == serverUrl &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode => Object.hash(serverUrl, apiKey);

  @override
  String toString() => 'ServerConfig(serverUrl: $serverUrl, apiKey: $apiKey)';
}
