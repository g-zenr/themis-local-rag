import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/models/health_status.dart';
import '../../../core/models/server_config.dart';
import '../../../shared/constants/api_constants.dart';

class LocalAiConfig {
  const LocalAiConfig({required this.enabled, required this.modelPath});

  final bool enabled;
  final String? modelPath;
}

final localAiConfigProvider = FutureProvider<LocalAiConfig>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return LocalAiConfig(
    enabled: await storage.getUseLocalAi(),
    modelPath: await storage.getLocalModelPath(),
  );
});

final serverConfigProvider = FutureProvider<ServerConfig?>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  final serverUrl = await storage.getServerUrl();
  final apiKey = await storage.getApiKey();

  if (serverUrl == null ||
      serverUrl.isEmpty ||
      apiKey == null ||
      apiKey.isEmpty) {
    return null;
  }

  return ServerConfig(serverUrl: serverUrl, apiKey: apiKey);
});

class TestConnectionParams {
  const TestConnectionParams({required this.serverUrl, required this.apiKey});

  final String serverUrl;
  final String apiKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestConnectionParams &&
        other.serverUrl == serverUrl &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode => Object.hash(serverUrl, apiKey);
}

final testConnectionProvider =
    FutureProvider.family<HealthStatus, TestConnectionParams>((
      ref,
      params,
    ) async {
      String baseUrl = params.serverUrl.trim();
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
          headers: {'X-API-Key': params.apiKey, 'Accept': 'application/json'},
        ),
      );

      try {
        final response = await dio.get<Map<String, dynamic>>('/api/health');
        return HealthStatus.fromJson(response.data!);
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      }
    });

class SaveSettingsParams {
  const SaveSettingsParams({
    required this.useLocalAi,
    this.localModelPath,
    required this.serverUrl,
    required this.apiKey,
  });

  final bool useLocalAi;
  final String? localModelPath;
  final String serverUrl;
  final String apiKey;
}

final saveSettingsProvider = FutureProvider.family<void, SaveSettingsParams>((
  ref,
  params,
) async {
  final storage = ref.read(secureStorageServiceProvider);

  await storage.setUseLocalAi(params.useLocalAi);
  await storage.setLocalModelPath(params.localModelPath);

  await storage.setServerUrl(params.serverUrl.trim());
  await storage.setApiKey(params.apiKey.trim());

  ref.invalidate(localAiConfigProvider);
  ref.invalidate(serverConfigProvider);
  ref.invalidate(hasServerConfigProvider);
});
