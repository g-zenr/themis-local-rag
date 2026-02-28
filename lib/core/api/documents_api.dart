import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/api_exception.dart';
import '../models/document.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// DocumentsApi – CRUD operations for uploaded documents.
// ---------------------------------------------------------------------------

class DocumentsApi {
  final ApiClient _apiClient;

  DocumentsApi(this._apiClient);

  /// Fetches the list of all documents from the server.
  ///
  /// The API response shape is `{ "data": [ ... ] }`.
  /// Returns an empty list when no documents exist.
  Future<List<Document>> getDocuments() async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.get<Map<String, dynamic>>('/api/documents');

      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Deletes the document with the given [documentId].
  ///
  /// The server returns `204 No Content` on success. If the document is not
  /// found the server returns `404` and the resulting [ApiException] will
  /// carry the message *"Document not found. It may have already been
  /// deleted."*.
  Future<void> deleteDocument(String documentId) async {
    try {
      final dio = await _apiClient.dio;
      await dio.delete<void>('/api/document/$documentId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final documentsApiProvider = Provider<DocumentsApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentsApi(apiClient);
});
