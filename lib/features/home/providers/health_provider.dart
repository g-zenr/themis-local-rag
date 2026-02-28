import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/local/local_ai_service.dart';
import '../../../core/local/local_documents_service.dart';
import '../../../core/models/health_status.dart';
import '../../../shared/constants/api_constants.dart';

/// Polls the server's `/api/health` endpoint every 30 seconds and emits the
/// latest [HealthStatus].
///
/// On error the stream yields an error state so that the UI can display an
/// appropriate banner.
final healthStatusProvider = StreamProvider<HealthStatus>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final localDocs = ref.read(localDocumentsServiceProvider);
  final localAi = ref.read(localAiServiceProvider);

  // The controller is used to push events from the periodic timer.
  final controller = StreamController<HealthStatus>();

  // We keep a reference to the Dio instance so it can be reused across ticks.
  Dio? dio;

  /// Performs a single health check.
  Future<void> tick() async {
    try {
      final useLocalAi = await storage.getUseLocalAi();
      if (useLocalAi) {
        final totalChunks = await localDocs.getTotalChunkCount();
        controller.add(
          HealthStatus(
            status: 'ok',
            database: 'connected',
            modelLoaded: localAi.isLoaded,
            totalChunks: totalChunks,
            indexedChunks: totalChunks,
          ),
        );
        return;
      }

      // Lazily build the Dio client on the first tick (or rebuild if the
      // config may have changed).
      if (dio == null) {
        final serverUrl = await storage.getServerUrl();
        final apiKey = await storage.getApiKey();

        if (serverUrl == null ||
            serverUrl.isEmpty ||
            apiKey == null ||
            apiKey.isEmpty) {
          controller.addError(
            const ApiException(
              message:
                  'Server configuration is missing. '
                  'Please configure the server in Settings.',
            ),
          );
          return;
        }

        String baseUrl = serverUrl.trim();
        if (baseUrl.endsWith('/')) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }

        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: ApiConstants.defaultTimeout,
            receiveTimeout: ApiConstants.defaultTimeout,
            headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
          ),
        );
      }

      final response = await dio!.get<Map<String, dynamic>>('/api/health');
      controller.add(HealthStatus.fromJson(response.data!));
    } on DioException catch (e) {
      controller.addError(ApiException.fromDioException(e));
      // Reset the Dio instance so the next tick re-reads config.
      dio = null;
    } catch (e) {
      controller.addError(ApiException(message: e.toString()));
      dio = null;
    }
  }

  // Fire immediately on subscription, then every 30 seconds.
  tick();
  final timer = Timer.periodic(ApiConstants.healthCheckInterval, (_) => tick());

  // Clean up when the provider is disposed.
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
