import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/constants/api_constants.dart';
import '../errors/api_exception.dart';
import '../models/ask_request.dart';
import '../models/ask_response.dart';
import '../models/citation.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// SSE stream event types
// ---------------------------------------------------------------------------

/// Sealed class representing the different event types emitted by the
/// `/api/ask/stream` SSE endpoint.
sealed class AskStreamEvent {
  const AskStreamEvent();
}

/// A single token (word / sub-word) to append to the running answer.
class TokenEvent extends AskStreamEvent {
  final String token;
  const TokenEvent(this.token);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TokenEvent && other.token == token;

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() => 'TokenEvent(token: $token)';
}

/// The final list of citations that accompany the generated answer.
class CitationsEvent extends AskStreamEvent {
  final List<Citation> citations;
  const CitationsEvent(this.citations);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CitationsEvent) return false;
    if (other.citations.length != citations.length) return false;
    for (var i = 0; i < citations.length; i++) {
      if (other.citations[i] != citations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(citations);

  @override
  String toString() => 'CitationsEvent(citations: $citations)';
}

/// The server reported an error inside the SSE stream.
class ErrorEvent extends AskStreamEvent {
  final String message;
  const ErrorEvent(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ErrorEvent && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ErrorEvent(message: $message)';
}

/// Signals the end of the stream (`data: [DONE]`).
class DoneEvent extends AskStreamEvent {
  const DoneEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DoneEvent;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DoneEvent()';
}

// ---------------------------------------------------------------------------
// AskApi – POST /api/ask  &  POST /api/ask/stream
// ---------------------------------------------------------------------------

class AskApi {
  final ApiClient _apiClient;

  AskApi(this._apiClient);

  // -----------------------------------------------------------------------
  // Non-streaming endpoint
  // -----------------------------------------------------------------------

  /// Sends a question to `/api/ask` and waits for the complete response.
  ///
  /// Returns an [AskResponse] containing the full answer text and citations.
  Future<AskResponse> ask(AskRequest request) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post<Map<String, dynamic>>(
        '/api/ask',
        data: request.toJson(),
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AskResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // -----------------------------------------------------------------------
  // Streaming endpoint (SSE)
  // -----------------------------------------------------------------------

  /// Sends a question to `/api/ask/stream` and returns a [Stream] of
  /// [AskStreamEvent]s.
  ///
  /// The stream emits:
  /// - [TokenEvent] for each incremental token of the answer.
  /// - [CitationsEvent] once, containing all citations for the answer.
  /// - [ErrorEvent] if the server signals an error inside the stream.
  /// - [DoneEvent] when the stream is complete.
  ///
  /// Pass a [cancelToken] to abort the request mid-stream.
  Stream<AskStreamEvent> askStream(
    AskRequest request, {
    CancelToken? cancelToken,
  }) async* {
    late final Response<ResponseBody> response;

    try {
      final dio = await _apiClient.dio;

      response = await dio.post<ResponseBody>(
        '/api/ask/stream',
        data: request.toJson(),
        options: Options(
          headers: {'Accept': 'text/event-stream'},
          responseType: ResponseType.stream,
          // Give the model more time to produce the first token.
          receiveTimeout: ApiConstants.streamingFirstTokenTimeout,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return; // Cancelled by caller – end the stream silently.
      }
      throw ApiException.fromDioException(e);
    }

    // Transform the raw byte stream into SSE events.
    yield* _parseSSEStream(response.data!.stream);
  }

  /// Parses a raw SSE byte stream into [AskStreamEvent]s.
  ///
  /// SSE lines follow the format:
  /// ```
  /// data: {"token": "word"}
  /// data: {"citations": [...]}
  /// data: {"error": "msg"}
  /// data: [DONE]
  /// ```
  Stream<AskStreamEvent> _parseSSEStream(
    Stream<List<int>> byteStream,
  ) async* {
    // Buffer for incomplete UTF-8 lines that span chunk boundaries.
    String buffer = '';

    await for (final chunk in byteStream) {
      buffer += utf8.decode(chunk, allowMalformed: true);

      // SSE events are delimited by newlines.
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        // Only process lines that start with "data: ".
        if (!line.startsWith('data: ')) continue;

        final payload = line.substring(6); // strip "data: "

        // Sentinel value indicating end of stream.
        if (payload == '[DONE]') {
          yield const DoneEvent();
          return;
        }

        // Try to parse the JSON payload.
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;

          if (json.containsKey('token')) {
            yield TokenEvent(json['token'] as String);
          } else if (json.containsKey('citations')) {
            final citationsList = (json['citations'] as List<dynamic>)
                .map((c) => Citation.fromJson(c as Map<String, dynamic>))
                .toList();
            yield CitationsEvent(citationsList);
          } else if (json.containsKey('error')) {
            yield ErrorEvent(json['error'] as String);
          }
        } on FormatException {
          // Ignore malformed JSON lines – best-effort parsing.
          continue;
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final askApiProvider = Provider<AskApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AskApi(apiClient);
});
