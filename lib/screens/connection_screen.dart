import 'package:chatbot/constant.dart';
import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import 'chat_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'translator_screen.dart'; // Import your translator screen

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isConnecting = false;
  String _connectionStatus = 'Ready to connect';
  bool _connectionFailed = false;

  final List<String> _aiTypes = ['Text Generation', 'Translator'];
  String _selectedAiType = 'Text Generation';

  final List<String> _models = [
    'deepseek-ai/deepseek-r1-0528',
    'microsoft/phi-4-mini-instruct',
    'meta/llama-3.3-70b-instruct',
    'nv-mistralai/mistral-nemo-12b-instruct',
  ];
  String _selectedModel = 'microsoft/phi-4-mini-instruct';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _connectToServer(String type) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting to server...';
      _connectionFailed = false;
    });

    try {
      bool connected = false;
      try {
        connected = await ChatbotService.connect();
        print('Connected to server: $connected');
      } catch (e) {
        setState(() {
          _isConnecting = false;
          _connectionStatus =
              'Could not connect to server. Please make sure the server is running.';
          _connectionFailed = true;
        });
        return;
      }

      try {
        await ChatbotService.sendModelname(_selectedModel);
      } catch (e) {
        // Optionally handle model send error
      }

      if (connected) {
        setState(() {
          _connectionStatus = 'Connected successfully!';
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          if (type == "Translator") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TranslatorScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          }
        }
      } else {
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Failed to connect to server';
          _connectionFailed = true;
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection error: ${e.toString()}';
        _connectionFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
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
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'AI Chatbot',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Connect to start chatting',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 40),

                  // AI Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings,
                          color: Colors.blueGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'AI Type:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedAiType,
                            isExpanded: true,
                            items:
                                _aiTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedAiType = value;
                                });
                                // If Translator is selected, navigate to TranslatorScreen
                                // if (value == 'Translator') {
                                //   Future.microtask(() {
                                //     Navigator.pushReplacement(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder:
                                //             (context) =>
                                //                 const TranslatorScreen(),
                                //       ),
                                //     );
                                //   });
                                // }
                              }
                            },
                            underline: Container(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Only show model dropdown if Text Generation is selected
                  if (_selectedAiType == 'Text Generation')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.memory,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Model:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedModel,
                              isExpanded: true,
                              items:
                                  _models
                                      .map(
                                        (model) => DropdownMenuItem(
                                          value: model,
                                          child: Text(model),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedModel = value;
                                  });
                                }
                              },
                              underline: Container(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Connection Status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _isConnecting
                            ? Column(
                              key: const ValueKey('connecting'),
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  _connectionStatus,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                            : Column(
                              key: const ValueKey('ready'),
                              children: [
                                if (_connectionFailed)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _connectionStatus,
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Connect Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _connectToServer(_selectedAiType);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                    ),
                                    child: const Text(
                                      'Connect to Server',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),

                  const SizedBox(height: 40),

                  // Server Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Server Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Host: ${baseUrl}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
