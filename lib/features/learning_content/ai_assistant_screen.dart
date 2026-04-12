import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/chat_service.dart';
import '../../widgets/circle_back_button.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
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
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ChatService.getHistory(size: 50);
      if (!mounted) return;
      setState(() {
        _messages.addAll(history);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('[AiAssistant] _loadHistory error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();

    final tempMsg = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.USER,
      content: text,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(tempMsg);
      _sending = true;
      _errorText = null;
    });
    _scrollToBottom();

    ChatMessageModel? reply;
    try {
      reply = await ChatService.sendMessage(text);
    } catch (e) {
      debugPrint('[AiAssistant] send error: $e'); // ignore: avoid_print
    }

    if (!mounted) return;

    setState(() {
      _sending = false;
      if (reply != null) {
        _messages.add(reply);
        _errorText = null;
      } else {
        _errorText = 'Не удалось получить ответ. Проверьте подключение и попробуйте снова.';
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: const [
                  CircleBackButton(),
                  Expanded(
                    child: Text(
                      'ИИ помощник',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),

            // Список сообщений
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              'Спроси всё, что хочешь: грамматику, слова, перевод или советы по произношению. '
                              'ИИ всегда готов помочь!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) =>
                              _MessageBubble(message: _messages[i]),
                        ),
            ),

            // Ошибка
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFC62828), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                              color: Color(0xFFC62828), fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _errorText = null),
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFFC62828)),
                      ),
                    ],
                  ),
                ),
              ),

            // Индикатор «ИИ печатает»
            if (_sending)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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

            // Поле ввода
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _controller,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Спроси ИИ-ассистента',
                  filled: true,
                  fillColor: const Color(0xFFE0DED8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
                  suffixIcon: IconButton(
                    tooltip: 'Отправить',
                    onPressed: _sending ? null : _send,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _sending ? Colors.grey : AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Пузырь сообщения
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                border: isUser ? null : Border.all(color: AppTheme.border),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.35,
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

// Анимация «три точки»
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
      builder: (context, child) {
        final v = _anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (v - i * 0.25).clamp(0.0, 1.0);
            final size =
                6.0 + 3.0 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
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
