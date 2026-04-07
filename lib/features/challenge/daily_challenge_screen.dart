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

  void _check() {
    // Бэкенд не отдаёт correctWord — показываем просто «Ответ отправлен»
    // (в реальном проекте нужен POST /daily-challenge/submit или поле answer)
    setState(() => _submitted = true);
  }

  void _reset() {
    setState(() {
      _remaining = List.from(_challenge!.letters);
      _chosen = [];
      _submitted = false;
      _isCorrect = false;
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

          // Собранное слово
          _answerRow(),
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
                onPressed: _chosen.isNotEmpty ? _check : null,
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

  Widget _answerRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _submitted ? AppTheme.primary : AppTheme.border,
          width: _submitted ? 1.5 : 1,
        ),
      ),
      child: _chosen.isEmpty
          ? const Text('Нажмите на буквы...',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14))
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: List.generate(
                _chosen.length,
                (i) => GestureDetector(
                  onTap: () => _removeLetter(i),
                  child: Container(
                    width: 34,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.chipFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Center(
                      child: Text(
                        _chosen[i].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
        color: AppTheme.chipFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle,
              color: AppTheme.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            'Ваш ответ: ${_chosen.join().toUpperCase()}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ответ принят! Следите за результатами.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _reset,
            child: const Text('Попробовать снова',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
