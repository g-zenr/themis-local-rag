import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  factory ApiException.fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (statusCode == 403) {
      return ApiException(
        message: 'Invalid API key. Check your settings.',
        statusCode: 403,
        originalError: error,
      );
    }

    if (statusCode == 422) {
      String message = 'Invalid input. Please check your entries.';
      if (responseData is Map<String, dynamic>) {
        final detail = responseData['detail'];
        if (detail is List && detail.isNotEmpty) {
          final firstError = detail[0];
          if (firstError is Map<String, dynamic>) {
            message = firstError['msg'] as String? ?? message;
          }
        }
      }
      return ApiException(
        message: message,
        statusCode: 422,
        originalError: error,
      );
    }

    if (statusCode == 404) {
      String message = 'Not found.';
      if (responseData is Map<String, dynamic>) {
        message = responseData['detail'] as String? ?? message;
      }
      return ApiException(
        message: message,
        statusCode: 404,
        originalError: error,
      );
    }

    if (statusCode == 500) {
      return ApiException(
        message: 'Server error. Please try again.',
        statusCode: 500,
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'Connection timed out. Check your network.',
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'Could not reach the server. Check your connection.',
        originalError: error,
      );
    }

    // Try to extract detail from response body
    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail is String) {
        return ApiException(
          message: detail,
          statusCode: statusCode,
          originalError: error,
        );
      }
    }

    return ApiException(
      message: error.message ?? 'An unexpected error occurred.',
      statusCode: statusCode,
      originalError: error,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
