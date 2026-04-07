import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scroll = ScrollController();
  final List<String> _userMessages = [];

  @override
  void dispose() {
    _scroll.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _userMessages.add(text));
    _controller.clear();
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Expanded(
                    child: Text(
                      'ИИ помощник',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _userMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          'Спроси всё, что хочешь: грамматику, слова, перевод или советы по произношению. '
                          'ИИ всегда готов помочь!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _userMessages.length,
                      itemBuilder: (context, i) {
                        final msg = _userMessages[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.84,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text(
                                    msg,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
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
                    onPressed: _submit,
                    icon: Icon(Icons.send_rounded, color: AppTheme.primary),
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
