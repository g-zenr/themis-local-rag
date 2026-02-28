import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/local/local_ai_service.dart';
import '../../../core/local/bundled_model_service.dart';
import '../../../core/local/local_documents_service.dart';
import '../../../core/models/ask_request.dart';
import '../../../core/models/ask_response.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/citation.dart';
import '../../../shared/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Chat history (in-memory session)
// ---------------------------------------------------------------------------

/// In-memory session history of chat messages. Cleared when the app restarts.
final chatHistoryProvider = StateProvider<List<ChatMessage>>((ref) => []);

// ---------------------------------------------------------------------------
// Streaming state
// ---------------------------------------------------------------------------

/// Tracks whether an answer is currently being streamed.
final isStreamingProvider = StateProvider<bool>((ref) => false);

/// Holds the partial answer text as it streams in (token by token).
final streamingAnswerProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Cancel token
// ---------------------------------------------------------------------------

/// A [CancelToken] that can be used to abort the current streaming request.
final _cancelTokenProvider = StateProvider<CancelToken?>((ref) => null);

// ---------------------------------------------------------------------------
// Ask question
// ---------------------------------------------------------------------------

/// Sends a question to the API and updates the chat history with the response.
///
/// First tries the streaming endpoint `POST /api/ask/stream`. If that fails
/// (e.g. 404 or network issue), falls back to the non-streaming endpoint
/// `POST /api/ask`.
///
/// The function adds the user message to [chatHistoryProvider] immediately,
/// then streams / fetches the assistant response and appends it when complete.
Future<void> askQuestion(WidgetRef ref, String question) async {
  try {
    final storage = ref.read(secureStorageServiceProvider);
    final useLocalAi = await storage.getUseLocalAi();

    if (useLocalAi) {
      await _askQuestionLocal(ref, question);
      return;
    }

    final serverUrl = await storage.getServerUrl();
    final apiKey = await storage.getApiKey();

    if (serverUrl == null ||
        serverUrl.isEmpty ||
        apiKey == null ||
        apiKey.isEmpty) {
      _addErrorMessage(
        ref,
        'Server not configured. Please check your settings.',
      );
      return;
    }

    String baseUrl = serverUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Add user message to history.
    final userMessage = ChatMessage(
      role: 'user',
      content: question,
      timestamp: DateTime.now(),
    );
    ref
        .read(chatHistoryProvider.notifier)
        .update((state) => [...state, userMessage]);

    // Mark streaming active.
    ref.read(isStreamingProvider.notifier).state = true;
    ref.read(streamingAnswerProvider.notifier).state = '';

    final cancelToken = CancelToken();
    ref.read(_cancelTokenProvider.notifier).state = cancelToken;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.defaultTimeout,
        receiveTimeout: ApiConstants.streamingFirstTokenTimeout,
        headers: {'X-API-Key': apiKey, 'Accept': 'text/event-stream'},
      ),
    );

    final requestBody = AskRequest(question: question).toJson();

    try {
      // ---- Try streaming endpoint first ----
      await _tryStreaming(ref, dio, requestBody, cancelToken);
    } catch (streamError) {
      // If cancelled, do nothing.
      if (cancelToken.isCancelled) {
        _finishStreaming(ref);
        return;
      }

      // ---- Fallback to non-streaming endpoint ----
      try {
        await _tryNonStreaming(ref, baseUrl, apiKey, requestBody, cancelToken);
      } catch (fallbackError) {
        if (cancelToken.isCancelled) {
          _finishStreaming(ref);
          return;
        }

        final message = fallbackError is ApiException
            ? fallbackError.message
            : 'Failed to get an answer. Please try again.';

        _addErrorMessage(ref, message);
        _finishStreaming(ref);
      }
    }
  } catch (e) {
    _addErrorMessage(ref, 'Unexpected failure while sending message: $e');
    _finishStreaming(ref);
  }
}

/// Cancels the active streaming request, if any.
void cancelStreaming(WidgetRef ref) {
  final cancelToken = ref.read(_cancelTokenProvider);
  cancelToken?.cancel('User cancelled');
  final localAi = ref.read(localAiServiceProvider);
  unawaited(localAi.stopGeneration());
  ref.read(isStreamingProvider.notifier).state = false;
  ref.read(streamingAnswerProvider.notifier).state = '';
  ref.read(_cancelTokenProvider.notifier).state = null;
}

// ---------------------------------------------------------------------------
// SSE streaming helper
// ---------------------------------------------------------------------------

Future<void> _tryStreaming(
  WidgetRef ref,
  Dio dio,
  Map<String, dynamic> requestBody,
  CancelToken cancelToken,
) async {
  final response = await dio.post<ResponseBody>(
    '/api/ask/stream',
    data: requestBody,
    options: Options(
      responseType: ResponseType.stream,
      headers: {'Accept': 'text/event-stream'},
    ),
    cancelToken: cancelToken,
  );

  final stream = response.data!.stream;
  final buffer = StringBuffer();
  List<Citation> citations = [];
  String answer = '';

  await for (final chunk in stream) {
    if (cancelToken.isCancelled) return;

    final decoded = utf8.decode(chunk, allowMalformed: true);
    buffer.write(decoded);

    // Process complete SSE lines from the buffer.
    final lines = buffer.toString().split('\n');
    // Keep the last (possibly incomplete) line in the buffer.
    buffer.clear();
    buffer.write(lines.last);

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      // SSE "data:" prefix
      if (line.startsWith('data:')) {
        final payload = line.substring(5).trim();

        if (payload == '[DONE]') {
          // Stream finished.
          _addAssistantMessage(ref, answer, citations);
          _finishStreaming(ref);
          return;
        }

        // Try to parse as JSON.
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;

          // Token event.
          if (json.containsKey('token')) {
            answer += json['token'] as String;
            ref.read(streamingAnswerProvider.notifier).state = answer;
          }

          // Citations event.
          if (json.containsKey('citations')) {
            citations = (json['citations'] as List<dynamic>)
                .map((e) => Citation.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          // Answer event (full answer in a single payload).
          if (json.containsKey('answer')) {
            answer = json['answer'] as String;
            ref.read(streamingAnswerProvider.notifier).state = answer;
          }
        } catch (_) {
          // Not JSON -- treat the payload as a raw text token.
          answer += payload;
          ref.read(streamingAnswerProvider.notifier).state = answer;
        }
      }
    }
  }

  // If stream ended without [DONE], still commit the message.
  if (answer.isNotEmpty) {
    _addAssistantMessage(ref, answer, citations);
  }
  _finishStreaming(ref);
}

// ---------------------------------------------------------------------------
// Non-streaming fallback
// ---------------------------------------------------------------------------

Future<void> _tryNonStreaming(
  WidgetRef ref,
  String baseUrl,
  String apiKey,
  Map<String, dynamic> requestBody,
  CancelToken cancelToken,
) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.defaultTimeout,
      receiveTimeout: ApiConstants.streamingFirstTokenTimeout,
      headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
    ),
  );

  try {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/ask',
      data: requestBody,
      cancelToken: cancelToken,
    );

    final askResponse = AskResponse.fromJson(response.data!);
    ref.read(streamingAnswerProvider.notifier).state = askResponse.answer;
    _addAssistantMessage(ref, askResponse.answer, askResponse.citations);
    _finishStreaming(ref);
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _addAssistantMessage(
  WidgetRef ref,
  String answer,
  List<Citation> citations,
) {
  final message = ChatMessage(
    role: 'assistant',
    content: answer,
    citations: citations,
    timestamp: DateTime.now(),
  );
  ref.read(chatHistoryProvider.notifier).update((state) => [...state, message]);
}

void _addErrorMessage(WidgetRef ref, String message) {
  final errorMessage = ChatMessage(
    role: 'assistant',
    content: message,
    timestamp: DateTime.now(),
  );
  ref
      .read(chatHistoryProvider.notifier)
      .update((state) => [...state, errorMessage]);
}

void _finishStreaming(WidgetRef ref) {
  ref.read(isStreamingProvider.notifier).state = false;
  ref.read(streamingAnswerProvider.notifier).state = '';
  ref.read(_cancelTokenProvider.notifier).state = null;
}

Future<void> _askQuestionLocal(WidgetRef ref, String question) async {
  final storage = ref.read(secureStorageServiceProvider);
  var modelPath = await storage.getLocalModelPath();
  final priorHistory = ref.read(chatHistoryProvider);

  if (modelPath == null || modelPath.trim().isEmpty) {
    final bundledService = ref.read(bundledModelServiceProvider);
    try {
      modelPath = await bundledService.ensureDefaultModelInstalled();
      await storage.setLocalModelPath(modelPath);
    } catch (_) {
      // Continue to config error below.
    }
  }

  if (modelPath == null || modelPath.trim().isEmpty) {
    _addErrorMessage(
      ref,
      'Local model not configured. Open Settings and select a GGUF model.',
    );
    return;
  }

  final userMessage = ChatMessage(
    role: 'user',
    content: question,
    timestamp: DateTime.now(),
  );
  ref
      .read(chatHistoryProvider.notifier)
      .update((state) => [...state, userMessage]);

  ref.read(isStreamingProvider.notifier).state = true;
  ref.read(streamingAnswerProvider.notifier).state = '';

  final cancelToken = CancelToken();
  ref.read(_cancelTokenProvider.notifier).state = cancelToken;

  final localAi = ref.read(localAiServiceProvider);
  final docs = ref.read(localDocumentsServiceProvider);

  try {
    await localAi.ensureLoaded(modelPath);

    var hits = await docs.searchChunks(
      question,
      topK: ApiConstants.defaultTopK,
    );

    if (hits.isEmpty) {
      final expandedQuery = _buildExpandedRetrievalQuery(
        question,
        priorHistory,
      );
      if (expandedQuery != question) {
        hits = await docs.searchChunks(
          expandedQuery,
          topK: ApiConstants.defaultTopK,
        );
      }
    }

    if (hits.isEmpty) {
      final recentCitations = _extractRecentCitations(
        priorHistory,
        maxCount: ApiConstants.defaultTopK,
      );
      if (recentCitations.isNotEmpty) {
        hits = await docs.getChunksForCitations(
          recentCitations,
          topK: ApiConstants.defaultTopK,
        );
      }
    }

    if (hits.isEmpty) {
      _addAssistantMessage(
        ref,
        'No information found in your uploaded documents. '
        'Try uploading a relevant document first.',
        const <Citation>[],
      );
      _finishStreaming(ref);
      return;
    }

    final citations = hits
        .map((hit) => Citation(document: hit.document, section: hit.section))
        .toList(growable: false);

    final prompt = _buildLocalRagPrompt(question, hits, priorHistory);
    var answer = await _generateLocalAnswer(
      ref,
      localAi: localAi,
      prompt: prompt,
      cancelToken: cancelToken,
      profile: LocalGenerationProfile.normal,
    );

    if (!cancelToken.isCancelled && _looksDegenerateAnswer(answer)) {
      ref.read(streamingAnswerProvider.notifier).state = '';
      answer = await _generateLocalAnswer(
        ref,
        localAi: localAi,
        prompt:
            '$prompt\n'
            'Write in plain text with normal sentences only. '
            'Do not output punctuation-only lines or separators.',
        cancelToken: cancelToken,
        profile: LocalGenerationProfile.stable,
      );
    }

    if (!cancelToken.isCancelled) {
      var cleaned = _sanitizeLocalAnswer(answer);
      if (cleaned.isEmpty || _looksDegenerateAnswer(cleaned)) {
        cleaned = _buildExtractiveFallbackAnswer(question, hits);
      }
      _addAssistantMessage(
        ref,
        cleaned.isEmpty
            ? 'No information found in your uploaded documents.'
            : cleaned,
        citations,
      );
    }
  } catch (e) {
    final message = e is ApiException
        ? e.message
        : 'Local AI failed: ${e.toString()}';
    _addErrorMessage(ref, message);
  } finally {
    _finishStreaming(ref);
  }
}

Future<String> _generateLocalAnswer(
  WidgetRef ref, {
  required LocalAiService localAi,
  required String prompt,
  required CancelToken cancelToken,
  required LocalGenerationProfile profile,
}) async {
  final stream = await localAi.streamPrompt(prompt, profile: profile);
  var answer = '';
  await for (final token in stream) {
    if (cancelToken.isCancelled) {
      break;
    }
    answer += token;
    ref.read(streamingAnswerProvider.notifier).state = answer;
  }
  return answer;
}

String _buildLocalRagPrompt(
  String question,
  List<LocalChunkHit> hits,
  List<ChatMessage> priorHistory,
) {
  final contextBuffer = StringBuffer();
  for (var i = 0; i < hits.length; i++) {
    final hit = hits[i];
    final snippet = _compressChunkForPrompt(question, hit.content);
    contextBuffer
      ..writeln('[${i + 1}] ${hit.document} - ${hit.section}')
      ..writeln(snippet)
      ..writeln();
  }

  final convoContext = _buildRecentConversationContext(priorHistory);
  final convoBlock = convoContext.isEmpty
      ? ''
      : 'Recent conversation:\n$convoContext\n\n';

  return '''
<|system|>
You are Athena, a strict document-grounded assistant.
Use only the provided context.
If the answer is not in the context, reply exactly:
No information found in your uploaded documents.
Keep the answer concise (about 4-7 short sentences) unless the user
explicitly asks for a detailed explanation.
</s>
<|user|>
${convoBlock}Context:
${contextBuffer.toString()}
Question: $question
</s>
<|assistant|>
''';
}

String _buildExpandedRetrievalQuery(String question, List<ChatMessage> history) {
  final normalized = _normalizeForRetrieval(question);
  if (!_isLikelyFollowUp(normalized)) {
    return question;
  }

  final previousUser = _lastMessageByRole(history, 'user');
  final previousAssistant = _lastMessageByRole(history, 'assistant');

  final parts = <String>[question];
  if (previousUser != null && previousUser.content.trim().isNotEmpty) {
    parts.add('Previous question: ${previousUser.content.trim()}');
  }
  if (previousAssistant != null && previousAssistant.content.trim().isNotEmpty) {
    parts.add(
      'Previous answer: ${_trimText(previousAssistant.content.trim(), 220)}',
    );
  }
  return parts.join('\n');
}

List<Citation> _extractRecentCitations(
  List<ChatMessage> history, {
  int maxCount = 3,
}) {
  final citations = <Citation>[];
  for (var i = history.length - 1; i >= 0; i--) {
    final message = history[i];
    if (message.role != 'assistant' || message.citations.isEmpty) {
      continue;
    }

    for (final citation in message.citations) {
      if (!citations.contains(citation)) {
        citations.add(citation);
      }
      if (citations.length >= maxCount) {
        return citations;
      }
    }
  }
  return citations;
}

String _buildRecentConversationContext(List<ChatMessage> history) {
  if (history.isEmpty) return '';

  final selected = <ChatMessage>[];
  for (var i = history.length - 1; i >= 0; i--) {
    final message = history[i];
    if (message.role != 'user' && message.role != 'assistant') {
      continue;
    }
    selected.add(message);
    if (selected.length >= 4) {
      break;
    }
  }

  if (selected.isEmpty) return '';
  final ordered = selected.reversed.toList(growable: false);
  final buffer = StringBuffer();

  for (final message in ordered) {
    final role = message.role == 'user' ? 'User' : 'Assistant';
    final content = _trimText(message.content.trim(), 220);
    buffer.writeln('$role: $content');
  }

  return buffer.toString().trim();
}

String _compressChunkForPrompt(
  String query,
  String content, {
  int maxChars = 420,
}) {
  final clean = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length <= maxChars) {
    return clean;
  }

  final lower = clean.toLowerCase();
  final keywords = _queryKeywords(query);
  var bestIndex = -1;

  for (final token in keywords) {
    final idx = lower.indexOf(token);
    if (idx >= 0) {
      bestIndex = idx;
      break;
    }
  }

  if (bestIndex < 0) {
    return '${clean.substring(0, maxChars)}...';
  }

  final half = maxChars ~/ 2;
  var start = bestIndex - half;
  if (start < 0) {
    start = 0;
  }
  var end = start + maxChars;
  if (end > clean.length) {
    end = clean.length;
    start = end - maxChars;
    if (start < 0) {
      start = 0;
    }
  }

  final snippet = clean.substring(start, end).trim();
  final prefix = start > 0 ? '... ' : '';
  final suffix = end < clean.length ? ' ...' : '';
  return '$prefix$snippet$suffix';
}

List<String> _queryKeywords(String query) {
  return query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.length >= 4)
      .toSet()
      .toList(growable: false);
}

String _normalizeForRetrieval(String input) {
  return input.trim().toLowerCase();
}

bool _isLikelyFollowUp(String normalizedQuestion) {
  final words = normalizedQuestion
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);

  if (words.length <= 3) {
    return true;
  }

  const followUpMarkers = <String>[
    'explain',
    'further',
    'more',
    'clarify',
    'continue',
    'elaborate',
    'detail',
    'what about',
    'how about',
    'and',
    'it',
    'that',
    'this',
  ];

  for (final marker in followUpMarkers) {
    if (normalizedQuestion.contains(marker)) {
      return true;
    }
  }

  return false;
}

ChatMessage? _lastMessageByRole(List<ChatMessage> history, String role) {
  for (var i = history.length - 1; i >= 0; i--) {
    final message = history[i];
    if (message.role == role) {
      return message;
    }
  }
  return null;
}

String _trimText(String input, int maxChars) {
  if (input.length <= maxChars) {
    return input;
  }
  return '${input.substring(0, maxChars)}...';
}

String _sanitizeLocalAnswer(String answer) {
  final raw = answer.trim();
  if (raw.isEmpty) return '';

  final lines = raw.split('\n');
  final kept = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (_isPunctuationOnlyLine(trimmed)) continue;
    kept.add(trimmed);
  }

  if (kept.isEmpty) {
    return raw;
  }
  return kept.join('\n').trim();
}

bool _isPunctuationOnlyLine(String line) {
  final lettersDigits = RegExp(r'[A-Za-z0-9]').allMatches(line).length;
  if (lettersDigits > 0) return false;
  return line.length >= 2;
}

bool _looksDegenerateAnswer(String answer) {
  final text = answer.trim();
  if (text.isEmpty) return true;

  final lettersDigits = RegExp(r'[A-Za-z0-9]').allMatches(text).length;
  final punct = RegExp(r'[^A-Za-z0-9\s]').allMatches(text).length;
  final wordCount = text
      .split(RegExp(r'\s+'))
      .where((w) => w.trim().isNotEmpty)
      .length;

  if (RegExp(r'(.)\1{7,}').hasMatch(text)) {
    return true;
  }
  if (lettersDigits < 12 && punct > lettersDigits) {
    return true;
  }
  if (lettersDigits > 0 && punct / lettersDigits > 1.2) {
    return true;
  }

  var punctuationOnlyLines = 0;
  for (final line in text.split('\n')) {
    if (_isPunctuationOnlyLine(line.trim())) {
      punctuationOnlyLines++;
    }
  }
  if (punctuationOnlyLines >= 2) {
    return true;
  }

  if (wordCount <= 3 && punct >= 4) {
    return true;
  }

  return false;
}

String _buildExtractiveFallbackAnswer(String question, List<LocalChunkHit> hits) {
  final keywords = _queryKeywords(question);
  final candidates = <_SentenceCandidate>[];

  for (final hit in hits) {
    final sentences = hit.content
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'(?<=[.!?])\s+'));
    for (final sentence in sentences) {
      final clean = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (clean.length < 30) continue;
      final lower = clean.toLowerCase();
      var score = 0;
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          score += 2;
        }
      }
      if (score == 0 && candidates.isNotEmpty) continue;
      candidates.add(_SentenceCandidate(clean, score));
    }
  }

  if (candidates.isEmpty) {
    final first = hits.firstOrNull;
    if (first == null) {
      return 'No information found in your uploaded documents.';
    }
    return _trimText(
      first.content.replaceAll(RegExp(r'\s+'), ' ').trim(),
      380,
    );
  }

  candidates.sort((a, b) => b.score.compareTo(a.score));
  final selected = <String>[];
  for (final candidate in candidates) {
    if (selected.any((s) => s == candidate.text)) continue;
    selected.add(candidate.text);
    if (selected.length >= 3) break;
  }

  return selected.join(' ');
}

class _SentenceCandidate {
  const _SentenceCandidate(this.text, this.score);

  final String text;
  final int score;
}
