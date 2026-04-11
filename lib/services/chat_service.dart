import 'dart:async';

import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

enum ChatRole {
  USER,
  ASSISTANT,
}

class ChatMessageModel {
  final String id;
  final ChatRole role;
  final String content;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == ChatRole.USER;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    debugPrint('[ChatMessageModel] fromJson: $json');
    // content may be under 'content', 'text', or 'message'
    final content = (json['content'] ?? json['text'] ?? json['message'] ?? '') as String;
    // role may be under 'role' or 'sender'
    final roleRaw = (json['role'] ?? json['sender'] ?? 'ASSISTANT') as String;
    return ChatMessageModel(
      id: (json['id'] ?? json['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString()) as String,
      role: _parseChatRole(roleRaw),
      content: content,
      createdAt: (json['createdAt'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()) as String,
    );
  }

  static ChatRole _parseChatRole(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return ChatRole.USER;
      case 'ASSISTANT':
      case 'AI':
      case 'BOT':
        return ChatRole.ASSISTANT;
      default:
        return ChatRole.ASSISTANT;
    }
  }
}

class ChatService {
  static final ApiClient _apiClient = ApiClient();

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Sends a message to the AI and returns the assistant reply.
  /// Retries up to [_maxRetries] times on timeout/network errors.
  /// Returns null if all attempts fail.
  static Future<ChatMessageModel?> sendMessage(String text) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('[ChatService] attempt $attempt/$_maxRetries: "$text"');

        final response = await _apiClient
            .post('/chat/message', data: {'message': text})
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw TimeoutException('[ChatService] request timed out'),
            );

        final data = response.data;
        debugPrint('[ChatService] raw response: $data');

        if (data == null) {
          debugPrint('[ChatService] response.data is null on attempt $attempt');
          lastError = Exception('Null response');
          await Future.delayed(_retryDelay);
          continue;
        }

        if (data is! Map<String, dynamic>) {
          debugPrint('[ChatService] unexpected type: ${data.runtimeType}');
          lastError = Exception('Unexpected response type');
          await Future.delayed(_retryDelay);
          continue;
        }

        // Unwrap common wrapper keys
        for (final key in ['assistantMessage', 'reply', 'response', 'message']) {
          if (data[key] is Map<String, dynamic>) {
            debugPrint('[ChatService] unwrapping key "$key"');
            return ChatMessageModel.fromJson(data[key] as Map<String, dynamic>);
          }
        }
        // Flat message object
        final msg = ChatMessageModel.fromJson(data);
        if (msg.content.isEmpty) {
          debugPrint('[ChatService] empty content on attempt $attempt');
          lastError = Exception('Empty response content');
          await Future.delayed(_retryDelay);
          continue;
        }
        return msg;

      } on TimeoutException catch (e) {
        debugPrint('[ChatService] timeout on attempt $attempt: $e');
        lastError = e;
        if (attempt < _maxRetries) await Future.delayed(_retryDelay);
      } catch (e, stack) {
        debugPrint('[ChatService] error on attempt $attempt: $e');
        debugPrint('[ChatService] $stack');
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < _maxRetries) await Future.delayed(_retryDelay);
      }
    }

    debugPrint('[ChatService] all $_maxRetries attempts failed. Last: $lastError');
    return null;
  }

  static Future<List<ChatMessageModel>> getHistory({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/history',
        params: {'page': page, 'size': size},
      );
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> content = data['content'] as List<dynamic>? ?? [];
      final messages = content
          .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
      // Reverse to chronological order (backend returns newest first)
      return messages.reversed.toList();
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
      return [];
    }
  }
}
