import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/router.dart';
import '../../shared/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

// ---------------------------------------------------------------------------
// ApiClient – thin Dio wrapper that configures base URL & auth headers
// from SecureStorageService.
// ---------------------------------------------------------------------------

class ApiClient {
  final SecureStorageService _storage;
  Dio? _dio;

  ApiClient(this._storage);

  /// Returns the lazily-initialised [Dio] instance whose base URL and
  /// `X-API-Key` header come from [SecureStorageService].
  ///
  /// Call [reset] whenever the stored credentials change so that the next
  /// access re-reads them.
  Future<Dio> get dio async {
    if (_dio != null) return _dio!;
    return _initialize();
  }

  Future<Dio> _initialize() async {
    final serverUrl = await _storage.getServerUrl() ?? '';
    final apiKey = await _storage.getApiKey() ?? '';

    _dio = Dio(
      BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: ApiConstants.defaultTimeout,
        receiveTimeout: ApiConstants.defaultTimeout,
        sendTimeout: ApiConstants.defaultTimeout,
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    return _dio!;
  }

  /// Invalidates the cached [Dio] instance so that the next call to [dio]
  /// re-reads the server URL and API key from secure storage.
  void reset() {
    _dio = null;
  }

  /// Creates a one-off [Dio] instance configured with the given [serverUrl]
  /// and [apiKey]. Useful for the Settings screen "Test Connection" flow
  /// where the user provides credentials that have not been persisted yet.
  Future<Dio> createTestClient(String serverUrl, String apiKey) async {
    return Dio(
      BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: ApiConstants.defaultTimeout,
        receiveTimeout: ApiConstants.defaultTimeout,
        sendTimeout: ApiConstants.defaultTimeout,
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(storage);
});
