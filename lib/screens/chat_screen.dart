import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chatbot_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'connection_screen.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _animationController;
  StreamSubscription<SocketResponse>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addWelcomeMessage();
    _listenToServerMessages();
  }

  String _formatMarkdown(String message) {
    // Example: Convert Markdown syntax to Flutter-compatible text
    // You can use a Markdown package like flutter_markdown for advanced rendering
    return message.replaceAll('**', '').replaceAll('_', '');
  }

  void _listenToServerMessages() {
    _messageSubscription = ChatbotService.messageStream?.listen((response) {
      // If using ChatbotResponse objects:
      final type = response.type;
      final message = response.message;

      if (type == 'error') {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          // Optionally, navigate to connection screen:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ConnectionScreen()),
          );
        }
        return;
      }

      if (type == 'response') {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add(
              Message(text: message, isUser: false, timestamp: DateTime.now()),
            );
          });
          _scrollToBottom();
        }
      }
    });
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            Message(
              text:
                  'Hello! 👋 I\'m your AI assistant. How can I help you today?',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Send message to server via socket
    await ChatbotService.sendMessage(text);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Handle back button press - FIXED VERSION
  Future<void> _handleBackPress() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Disconnecting...'),
                ],
              ),
            ),
      );

      // Disconnect from server
      await ChatbotService.disconnect();

      // Close loading dialog and navigate back to connection screen
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Navigate back to connection screen using pushReplacement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
        );
      }
    } catch (e) {
      print('Error during disconnect: $e');
      // Even if disconnect fails, still navigate back
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBackPress();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _handleBackPress,
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    ChatbotService.isConnected ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          ChatbotService.isConnected
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onSubmitted: _sendMessage,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
