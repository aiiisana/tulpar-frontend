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
    return ChatMessageModel(
      id: json['id'] as String,
      role: _parseChatRole(json['role'] as String),
      content: json['content'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  static ChatRole _parseChatRole(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return ChatRole.USER;
      case 'ASSISTANT':
        return ChatRole.ASSISTANT;
      default:
        return ChatRole.USER;
    }
  }
}

class ChatService {
  static final ApiClient _apiClient = ApiClient();

  static Future<ChatMessageModel?> sendMessage(String text) async {
    try {
      final response = await _apiClient.post(
        '/chat/message',
        data: {'message': text},
      );
      return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      return null;
    }
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
