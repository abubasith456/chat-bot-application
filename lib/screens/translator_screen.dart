import 'package:chatbot/models/message.dart';
import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'connection_screen.dart';
import 'dart:async';
import '../constant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _animationController;
  StreamSubscription<SocketResponse>? _messageSubscription;

  String _selectedFromLang = "en";
  String _selectedToLang = "ar";
  List<String> _fromLanguages = [];
  List<String> _toLanguages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _showFetchingLoader();
    _fetchLanguages();
    _addWelcomeMessage();
    _listenToServerMessages();
  }

  void _showFetchingLoader() {
    setState(() {
      _isTyping = true;
    });
  }

  Future<void> _fetchLanguages() async {
    final url = Uri.parse('$baseUrl/languages');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _fromLanguages = List<String>.from(data['from_text']);
          _toLanguages = List<String>.from(data['to_text']);
          _selectedFromLang = _fromLanguages.first;
          _selectedToLang = _toLanguages.first;
          _isTyping = false; // Hide loader after fetching
        });
      } else {
        setState(() {
          _isTyping = false;
        });
        // fallback or error handling
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      // fallback or error handling
    }
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
                  'Welcome to the Translator! Select languages and enter text to translate.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _onLanguageChanged(String fromLang, String toLang) async {
    setState(() {
      _selectedFromLang = fromLang;
      _selectedToLang = toLang;
    });
    await ChatbotService.sendLanguages(fromLang, toLang);
  }

  void _sendTranslateRequest(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Send language selection and text to translate
    await ChatbotService.sendLanguages(_selectedFromLang, _selectedToLang);
    await ChatbotService.sendTranslateText(text);
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

  Future<void> _handleBackPress() async {
    try {
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
      await ChatbotService.disconnect();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
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
        return false;
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
          title: const Text(
            'Translator',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedFromLang,
                      isExpanded: true,
                      items:
                          _fromLanguages
                              .map(
                                (lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(languageNames[lang] ?? lang),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFromLang = value;
                          });
                          _onLanguageChanged(
                            _selectedFromLang,
                            _selectedToLang,
                          );
                        }
                      },
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedToLang,
                      isExpanded: true,
                      items:
                          _toLanguages
                              .map(
                                (lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(languageNames[lang] ?? lang),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedToLang = value;
                          });
                          _onLanguageChanged(
                            _selectedFromLang,
                            _selectedToLang,
                          );
                        }
                      },
                      underline: Container(),
                    ),
                  ),
                ],
              ),
            ),
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
            Container(
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
                          hintText: 'Enter text to translate...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: _sendTranslateRequest,
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendTranslateRequest(_textController.text),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
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
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
