import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import 'citation_chip.dart';

/// A chat bubble widget for displaying assistant answers.
///
/// Left-aligned with a surface-coloured background. Shows the answer text
/// followed by a collapsible "Sources" section that lists each [Citation]
/// as a [CitationChip].
class AnswerBubble extends StatefulWidget {
  /// The assistant chat message to display.
  final ChatMessage message;

  /// Whether this bubble is currently being streamed (shows a blinking cursor).
  final bool isStreaming;

  const AnswerBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  State<AnswerBubble> createState() => _AnswerBubbleState();
}

class _AnswerBubbleState extends State<AnswerBubble>
    with SingleTickerProviderStateMixin {
  bool _sourcesExpanded = false;
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isStreaming) {
      _cursorController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnswerBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_cursorController.isAnimating) {
      _cursorController.repeat(reverse: true);
    } else if (!widget.isStreaming && _cursorController.isAnimating) {
      _cursorController.stop();
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasCitations = widget.message.citations.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Answer text with optional blinking cursor.
              if (widget.message.content.isNotEmpty)
                RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(text: widget.message.content),
                      if (widget.isStreaming)
                        WidgetSpan(
                          child: FadeTransition(
                            opacity: _cursorController,
                            child: Container(
                              width: 2,
                              height: 16,
                              margin: const EdgeInsets.only(left: 2),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else if (widget.isStreaming)
                // Just show blinking cursor while waiting for first token.
                FadeTransition(
                  opacity: _cursorController,
                  child: Container(
                    width: 2,
                    height: 16,
                    color: colorScheme.primary,
                  ),
                ),

              // Sources section (collapsible).
              if (hasCitations && !widget.isStreaming) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _sourcesExpanded = !_sourcesExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sourcesExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sources (${widget.message.citations.length})',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_sourcesExpanded) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.message.citations
                        .map((c) => CitationChip(citation: c))
                        .toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
