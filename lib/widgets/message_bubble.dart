import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: message.isUser ? 50 : 16,
        right: message.isUser ? 16 : 50,
      ),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient:
                message.isUser
                    ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(message.isUser ? 20 : 4),
              bottomRight: Radius.circular(message.isUser ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expanded message content
                  Expanded(
                    child:
                        message.isUser
                            ? DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: MarkdownBody(
                                data: message.text,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(color: Colors.white),
                                  strong: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  em: const TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  code: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            : MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ),
                            ),
                  ),
                  // Copy button aligned to top right of the bubble
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    tooltip: 'Copy',
                    padding: const EdgeInsets.only(
                      left: 8,
                      top: 0,
                      right: 0,
                      bottom: 0,
                    ),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color:
                      message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
