import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/api_exception.dart';
import '../models/upload_result.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// UploadApi – POST /api/upload-document (multipart/form-data)
// ---------------------------------------------------------------------------

class UploadApi {
  final ApiClient _apiClient;

  UploadApi(this._apiClient);

  /// Uploads a document file to the server.
  ///
  /// Parameters:
  /// - [filePath]: absolute path to the file on disk.
  /// - [fileName]: the display name of the file (e.g. `report.pdf`).
  /// - [title]: human-readable document title.
  /// - [year]: publication / reference year as a string.
  /// - [onSendProgress]: optional callback for tracking upload progress.
  ///   Receives `(int sent, int total)`.
  /// - [cancelToken]: optional [CancelToken] to abort the upload.
  ///
  /// Returns an [UploadResult] on success (HTTP 201).
  Future<UploadResult> uploadDocument({
    required String filePath,
    required String fileName,
    required String title,
    required String year,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = await _apiClient.dio;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'title': title,
        'year': year,
      });

      final response = await dio.post<Map<String, dynamic>>(
        '/api/upload-document',
        data: formData,
        options: Options(
          // Override the default JSON content type for multipart uploads.
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return UploadResult.fromJson(data);
    } on DioException catch (e) {
      // If the upload was intentionally cancelled, rethrow as-is so that
      // callers can distinguish cancellation from real errors.
      if (CancelToken.isCancel(e)) {
        rethrow;
      }
      throw ApiException.fromDioException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final uploadApiProvider = Provider<UploadApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UploadApi(apiClient);
});
