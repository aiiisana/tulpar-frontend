import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await ChatService.getHistory(size: 50);
    if (!mounted) return;
    setState(() {
      _messages.addAll(history);
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_sending) {
      debugPrint('[Chat] _send() blocked — already sending');
      return;
    }

    _controller.clear();

    // Optimistically add the user's message bubble immediately
    final tempUserMsg = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.USER,
      content: text,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(tempUserMsg);
      _sending = true;
      _errorText = null;
    });
    _scrollToBottom();

    debugPrint('[Chat] Sending message to AI: "$text"');

    ChatMessageModel? reply;
    try {
      // Backend AI call — may take up to ~90 s (OpenAI timeout 60 s + network)
      reply = await ChatService.sendMessage(text)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              debugPrint('[Chat] sendMessage timed out after 90 s');
              return null;
            },
          );
      debugPrint('[Chat] Got reply: ${reply?.content?.substring(0, (reply.content.length).clamp(0, 80))}');
    } catch (e) {
      debugPrint('[Chat] _send() caught unexpected error: $e');
      reply = null;
    }

    if (!mounted) return;

    setState(() {
      _sending = false;
      if (reply != null) {
        _messages.add(reply);
        _errorText = null;
      } else {
        _errorText =
            'Не удалось получить ответ от ИИ. Проверьте подключение и попробуйте снова.';
      }
    });
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ИИ помощник'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── История сообщений ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            _MessageBubble(message: _messages[i]),
                      ),
          ),

          // ── Ошибка ────────────────────────────────────────────────────
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorText = null),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFFC62828)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Индикатор «печатает» ───────────────────────────────────────
          if (_sending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _TypingDots(),
                        SizedBox(width: 8),
                        Text('ИИ отвечает...',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Поле ввода ─────────────────────────────────────────────────
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Напишите сообщение...',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: _sending ? Colors.grey.shade400 : AppTheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Пузырь сообщения ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primary,
              child: const Text('ИИ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight:
                      isUser ? Radius.zero : const Radius.circular(18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppTheme.border),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Три точки «печатает» ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = _anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (v - i * 0.25).clamp(0.0, 1.0);
            final size = 6.0 + 3.0 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Заглушка при пустой истории ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.chipFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Начните разговор!',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Задайте любой вопрос по\nказахскому языку',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
