import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/daily_challenge_service.dart';

/// Экран ежедневного задания «4 картинки — 1 слово».
///
/// Пользователь видит 4 изображения и набор букв.
/// Нажимает на буквы в нужном порядке → собирает слово.
/// Бэкенд не отдаёт правильный ответ, поэтому проверка —
/// только на стороне UI (сравнение с полем answer, если оно появится),
/// либо можно добавить кнопку «Показать ответ» через отдельный эндпоинт.
/// Пока реализуем интерфейс без проверки ответа.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  DailyChallengeModel? _challenge;
  bool _loading = true;
  bool _noChallenge = false;

  // Буквы, собранные пользователем
  List<String> _chosen = [];
  // Оставшиеся буквы
  late List<String> _remaining;
  // Флаги состояния
  bool _submitted = false;
  bool _isCorrect = false;
  bool _xpAwarded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenge = await DailyChallengeService.getToday();
    if (!mounted) return;
    if (challenge == null) {
      setState(() {
        _loading = false;
        _noChallenge = true;
      });
      return;
    }
    setState(() {
      _challenge = challenge;
      _remaining = List.from(challenge.letters);
      _chosen = [];
      _submitted = false;
      _isCorrect = false;
      _loading = false;
    });
  }

  void _pickLetter(int index) {
    if (_submitted) return;
    setState(() {
      _chosen.add(_remaining[index]);
      _remaining.removeAt(index);
    });
  }

  void _removeLetter(int index) {
    if (_submitted) return;
    setState(() {
      _remaining.add(_chosen[index]);
      _chosen.removeAt(index);
    });
  }

  Future<void> _check() async {
    if (_challenge == null) return;
    final answer = _chosen.join();

    // Сначала показываем, что проверяем
    setState(() => _submitted = true);

    final result = await DailyChallengeService.submitAnswer(
      challengeId: _challenge!.id,
      answer: answer,
    );

    if (!mounted) return;
    setState(() {
      _isCorrect = result.correct;
      _xpAwarded = result.xpAwarded > 0;
      // Сохраняем правильное слово из ответа бэкенда (на случай если correctWord был null)
      if (result.correctWord.isNotEmpty && _challenge!.correctWord == null) {
        _challenge = DailyChallengeModel(
          id:            _challenge!.id,
          challengeDate: _challenge!.challengeDate,
          letters:       _challenge!.letters,
          imageUrls:     _challenge!.imageUrls,
          wordLength:    _challenge!.wordLength,
          correctWord:   result.correctWord,
        );
      }
    });
  }

  /// Суффикс для «N букв» (русское склонение)
  String _wordSuffix(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 19) return '';
    if (mod10 == 1) return 'а';
    if (mod10 >= 2 && mod10 <= 4) return 'ы';
    return '';
  }

  void _reset() {
    setState(() {
      _remaining = List.from(_challenge!.letters);
      _chosen = [];
      _submitted = false;
      _isCorrect = false;
      _xpAwarded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ежедневное задание'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noChallenge
              ? _noTaskState()
              : _challengeBody(),
    );
  }

  // ── Нет задания на сегодня ────────────────────────────────────────────────

  Widget _noTaskState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined,
              color: AppTheme.textSecondary, size: 64),
          const SizedBox(height: 16),
          const Text('Задание на сегодня ещё не добавлено',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Загляните позже!',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Обновить',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Основной контент задания ──────────────────────────────────────────────

  Widget _challengeBody() {
    final ch = _challenge!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.chipFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ch.challengeDate,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '4 картинки — 1 слово',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Что объединяет эти изображения?',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Сетка 2×2 из картинок
          _imageGrid(ch.imageUrls),
          const SizedBox(height: 24),

          // Собранное слово (N ячеек по длине слова)
          _answerRow(),
          const SizedBox(height: 6),
          Text(
            '${ch.wordLength} букв${_wordSuffix(ch.wordLength)}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Буквы
          if (!_submitted)
            _letterPicker(),

          const SizedBox(height: 20),

          // Кнопки
          if (!_submitted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_chosen.length == (_challenge?.wordLength ?? 0)) ? _check : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Проверить',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _chosen.isNotEmpty ? _reset : null,
              child: const Text('Сбросить',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ] else
            _resultCard(),
        ],
      ),
    );
  }

  // ── Сетка 2×2 ─────────────────────────────────────────────────────────────

  Widget _imageGrid(List<String> urls) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(4, (i) {
        final url = i < urls.length ? urls[i] : null;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(i + 1),
                )
              : _imagePlaceholder(i + 1),
        );
      }),
    );
  }

  Widget _imagePlaceholder(int n) {
    return Container(
      color: AppTheme.border,
      child: Center(
        child: Text('Фото $n',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ),
    );
  }

  // ── Ряд с собранным ответом ───────────────────────────────────────────────
  // Показывает ровно wordLength ячеек: заполненные — с буквой,
  // пустые — пунктирная рамка. Нажатие на заполненную ячейку возвращает букву.

  Widget _answerRow() {
    final wordLen = _challenge?.wordLength ?? 0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(wordLen, (i) {
        final filled = i < _chosen.length;
        final letter = filled ? _chosen[i].toUpperCase() : '';
        return GestureDetector(
          onTap: filled && !_submitted ? () => _removeLetter(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 42,
            decoration: BoxDecoration(
              color: filled ? AppTheme.chipFill : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: filled ? AppTheme.primary : AppTheme.border,
                width: filled ? 1.5 : 1,
              ),
              boxShadow: filled
                  ? [
                      const BoxShadow(
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          color: Color(0x1A000000))
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: filled ? AppTheme.primary : Colors.transparent,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Выбор букв ────────────────────────────────────────────────────────────

  Widget _letterPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(
        _remaining.length,
        (i) => GestureDetector(
          onTap: () => _pickLetter(i),
          child: Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Color(0x14000000))
              ],
            ),
            child: Center(
              child: Text(
                _remaining[i].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Результат ─────────────────────────────────────────────────────────────

  Widget _resultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isCorrect
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _isCorrect ? Colors.green : Colors.red,
            width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect ? Colors.green : Colors.red,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _isCorrect ? 'Правильно!' : 'Не правильно',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: _isCorrect ? Colors.green : Colors.red),
          ),
          if (_isCorrect && _xpAwarded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD600)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                  SizedBox(width: 4),
                  Text('+10 XP',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF795548))),
                ],
              ),
            ),
          ],
          if (_isCorrect && !_xpAwarded && _submitted) ...[
            const SizedBox(height: 6),
            const Text(
              'XP за сегодня уже получены',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          if (!_isCorrect &&
              (_challenge?.correctWord ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Правильный ответ: ${_challenge!.correctWord!.toUpperCase()}',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          TextButton(
            onPressed: _reset,
            child: const Text('Повторить',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
