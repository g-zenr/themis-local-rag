import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/api_exception.dart';
import '../models/health_status.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// HealthApi – GET /api/health
// ---------------------------------------------------------------------------

class HealthApi {
  final ApiClient _apiClient;

  HealthApi(this._apiClient);

  /// Fetches the health status from the configured server.
  ///
  /// Returns a [HealthStatus] on success, or throws an [ApiException] if the
  /// request fails.
  Future<HealthStatus> getHealth() async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.get<Map<String, dynamic>>('/api/health');
      return HealthStatus.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Tests the connection with a specific server URL and API key that have
  /// not yet been persisted to secure storage.
  ///
  /// This is used by the Settings screen to validate credentials before
  /// saving them.
  Future<HealthStatus> testConnection(String serverUrl, String apiKey) async {
    try {
      final dio = await _apiClient.createTestClient(serverUrl, apiKey);
      final response = await dio.get<Map<String, dynamic>>('/api/health');
      return HealthStatus.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final healthApiProvider = Provider<HealthApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthApi(apiClient);
});
