import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../shared/constants/api_constants.dart';
import '../providers/ask_provider.dart';
import '../widgets/answer_bubble.dart';

/// The Ask screen (PRD F-5).
///
/// Displays a chat-style interface where the user can ask questions about
/// their indexed documents. Supports streaming responses with a blinking
/// cursor, citation display, and a character counter for the input.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final question = _textController.text.trim();
    if (question.length < ApiConstants.minQuestionLength) return;

    _textController.clear();
    setState(() {}); // Update char counter.

    _scrollToBottom();
    await askQuestion(ref, question);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final streamingAnswer = ref.watch(streamingAnswerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Auto-scroll when new messages arrive or streaming text updates.
    ref.listen<List<ChatMessage>>(chatHistoryProvider, (prev, next) {
      _scrollToBottom();
    });
    ref.listen<String>(streamingAnswerProvider, (prev, next) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
      ),
      body: Column(
        children: [
          // ---- Chat messages ----
          Expanded(
            child: chatHistory.isEmpty && !isStreaming
                ? _EmptyState(colorScheme: colorScheme, textTheme: textTheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: chatHistory.length + (isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Streaming bubble at the end.
                      if (index == chatHistory.length && isStreaming) {
                        return AnswerBubble(
                          message: ChatMessage(
                            role: 'assistant',
                            content: streamingAnswer,
                            timestamp: DateTime.now(),
                          ),
                          isStreaming: true,
                        );
                      }

                      final message = chatHistory[index];

                      if (message.role == 'user') {
                        return _UserBubble(message: message);
                      }

                      return AnswerBubble(message: message);
                    },
                  ),
          ),

          // ---- Input area ----
          _InputArea(
            controller: _textController,
            focusNode: _focusNode,
            isStreaming: isStreaming,
            onSend: _handleSend,
            onStop: () => cancelStreaming(ref),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _EmptyState({
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask a question',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type your question below to search through your indexed documents.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User chat bubble
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            message.content,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input area
// ---------------------------------------------------------------------------

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ValueChanged<String> onChanged;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final charCount = controller.text.length;
    final canSend = charCount >= ApiConstants.minQuestionLength && !isStreaming;
    final showCounter = charCount > ApiConstants.charCountWarningThreshold;
    final isOverLimit = charCount > ApiConstants.maxQuestionLength;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: ApiConstants.maxQuestionLength,
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          required maxLength}) =>
                      null, // We use our own counter.
                  onChanged: onChanged,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Ask about your documents...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Send / Stop button
              if (isStreaming)
                IconButton(
                  onPressed: onStop,
                  icon: Icon(
                    Icons.stop_circle_rounded,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Stop',
                )
              else
                IconButton(
                  onPressed: canSend ? onSend : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: canSend
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  tooltip: 'Send',
                ),
            ],
          ),

          // Character counter (shown when near limit).
          if (showCounter)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(
                '$charCount / ${ApiConstants.maxQuestionLength}',
                style: textTheme.labelSmall?.copyWith(
                  color: isOverLimit
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
