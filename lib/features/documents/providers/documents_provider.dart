import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/local/local_documents_service.dart';
import '../../../core/models/document.dart';
import '../../../shared/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Documents list provider
// ---------------------------------------------------------------------------

/// Fetches the list of documents from GET /api/documents.
///
/// Reads the server URL and API key from [SecureStorageService] and creates
/// a [Dio] instance to perform the request. The response is expected to be
/// `{ "data": [Document] }`.
final documentsProvider = FutureProvider<List<Document>>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  final useLocalAi = await storage.getUseLocalAi();

  if (useLocalAi) {
    final localDocs = ref.watch(localDocumentsServiceProvider);
    return localDocs.getDocuments();
  }

  final serverUrl = await storage.getServerUrl();
  final apiKey = await storage.getApiKey();

  if (serverUrl == null ||
      serverUrl.isEmpty ||
      apiKey == null ||
      apiKey.isEmpty) {
    throw const ApiException(
      message: 'Server not configured. Please check your settings.',
    );
  }

  // Normalise server URL (strip trailing slash).
  String baseUrl = serverUrl.trim();
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.defaultTimeout,
      receiveTimeout: ApiConstants.defaultTimeout,
      headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
    ),
  );

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/documents');
    final data = response.data!;
    final documents = (data['data'] as List<dynamic>)
        .map((e) => Document.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort by most recent first.
    documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return documents;
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
});

// ---------------------------------------------------------------------------
// Delete document provider
// ---------------------------------------------------------------------------

/// Deletes a document by its [id] via DELETE /api/document/{id}.
///
/// On success the [documentsProvider] is invalidated so the list refreshes.
final deleteDocumentProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final storage = ref.read(secureStorageServiceProvider);
  final useLocalAi = await storage.getUseLocalAi();

  if (useLocalAi) {
    final localDocs = ref.read(localDocumentsServiceProvider);
    await localDocs.deleteDocument(id);
    ref.invalidate(documentsProvider);
    return;
  }

  final serverUrl = await storage.getServerUrl();
  final apiKey = await storage.getApiKey();

  if (serverUrl == null ||
      serverUrl.isEmpty ||
      apiKey == null ||
      apiKey.isEmpty) {
    throw const ApiException(
      message: 'Server not configured. Please check your settings.',
    );
  }

  String baseUrl = serverUrl.trim();
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.defaultTimeout,
      receiveTimeout: ApiConstants.defaultTimeout,
      headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
    ),
  );

  try {
    await dio.delete<dynamic>('/api/document/$id');
    // Refresh the documents list after successful deletion.
    ref.invalidate(documentsProvider);
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
});
