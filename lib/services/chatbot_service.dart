import 'dart:convert';
import 'dart:async';
import 'package:chatbot/constant.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketResponse {
  final String type;
  final String message;

  SocketResponse({required this.type, required this.message});

  factory SocketResponse.fromJson(Map<String, dynamic> json) {
    return SocketResponse(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class ChatbotService {
  static WebSocketChannel? _channel;
  static StreamController<SocketResponse>? _messageController;
  static bool _isConnected = false;

  static String get _wsUrl {
    final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final uri = Uri.parse(baseUrl);
    return '$wsScheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ws/chat';
  }

  static Stream<SocketResponse>? get messageStream =>
      _messageController?.stream;
  static bool get isConnected => _isConnected;

  static Future<bool> connect() async {
    _messageController = StreamController<SocketResponse>.broadcast();
    final completer = Completer<bool>();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = false;

      _channel!.stream.listen(
        (data) {
          try {
            final msg = json.decode(data);
            final response = SocketResponse.fromJson(msg);
            if (response.type == 'response' || response.type == 'error') {
              _messageController?.add(response);
            }
            if (!_isConnected) {
              _isConnected = true;
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (e) {
            _messageController?.add(
              SocketResponse(
                type: 'error',
                message: 'Error parsing message: $data',
              ),
            );
          }
        },
        onError: (error) {
          _isConnected = false;
          _messageController?.add(
            SocketResponse(type: 'error', message: 'Connection error: $error'),
          );
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          _isConnected = false;
          _messageController?.add(
            SocketResponse(type: 'error', message: 'Connection closed.'),
          );
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _isConnected = false;
          _messageController?.add(
            SocketResponse(type: 'error', message: 'Connection timeout.'),
          );
          return false;
        },
      );
    } catch (e) {
      _isConnected = false;
      _messageController?.add(
        SocketResponse(type: 'error', message: 'Failed to connect: $e'),
      );
      return false;
    }
  }

  static Future<void> disconnect() async {
    await _channel?.sink.close();
    await _messageController?.close();
    _isConnected = false;
  }

  static Future<void> sendMessage(String userMessage) async {
    if (!_isConnected || _channel == null) return;
    final msg = json.encode({'type': 'message', 'text': userMessage});
    _channel!.sink.add(msg);
  }

  static Future<void> sendModelname(String modelName) async {
    if (!_isConnected || _channel == null) return;
    final msg = json.encode({'type': 'model', 'text': modelName});
    _channel!.sink.add(msg);
  }

  static Future<void> sendLanguages(String text_from, String text_to) async {
    if (!_isConnected || _channel == null) return;
    final msg = json.encode({
      'type': 'languages',
      'text': "",
      "text_from": text_from,
      "text_to": text_to,
    });
    _channel!.sink.add(msg);
  }

  static Future<void> sendTranslateText(String text) async {
    if (!_isConnected || _channel == null) return;
    final msg = json.encode({'type': 'translate', "text": text});
    _channel!.sink.add(msg);
  }
}
