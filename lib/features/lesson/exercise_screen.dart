import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/lesson_service.dart';
import '../../services/progress_service.dart';

/// Экран прохождения урока.
/// Показывает упражнения одно за одним.
/// После каждого — немедленная обратная связь (верно / нет).
/// В конце — итоговый экран с количеством правильных ответов.
class ExerciseScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const ExerciseScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<ExerciseModel> _exercises = [];
  int _current = 0;
  bool _loading = true;
  bool _submitted = false;
  bool? _lastCorrect;
  int _correctCount = 0;
  bool _finished = false;

  // Для sentence builder
  List<String> _chosenWords = [];
  List<String> _remainingWords = [];

  // Для multiple-choice
  String? _selectedOption;

  // Аудиоплеер для LISTENING
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _audioState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _load();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _audioState = state);
    });
  }

  Future<void> _load() async {
    final lesson = await LessonService.getLessonDetail(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _exercises = lesson?.exercises ?? [];
      _loading = false;
      if (_exercises.isNotEmpty) _prepareExercise(_exercises[0]);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _prepareExercise(ExerciseModel ex) {
    _submitted = false;
    _lastCorrect = null;
    _selectedOption = null;
    _audioPlayer.stop();
    _audioState = PlayerState.stopped;
    if (ex.type == ExerciseType.SENTENCE_BUILDER) {
      _remainingWords = List.from(ex.shuffledWords);
      _chosenWords = [];
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_audioState == PlayerState.playing) {
        await _audioPlayer.stop();
      } else {
        // Поддерживаем как http/https URL, так и assets пути
        if (url.startsWith('http://') || url.startsWith('https://')) {
          await _audioPlayer.play(UrlSource(url));
        } else {
          // Относительный путь — пробуем как URL через базовый адрес API
          final apiBase = const String.fromEnvironment(
            'API_BASE', defaultValue: 'http://localhost:8080');
          await _audioPlayer.play(UrlSource('$apiBase$url'));
        }
      }
    } catch (e) {
      debugPrint('[Audio] play error: $e');
    }
  }

  Future<void> _submit(String answer) async {
    if (_submitted) return;
    setState(() => _submitted = true);

    final ex = _exercises[_current];
    final result = await ProgressService.submit(
      exerciseId: ex.id,
      userAnswer: answer,
    );

    if (!mounted) return;
    setState(() {
      _lastCorrect = result?.correct ?? false;
      if (_lastCorrect == true) _correctCount++;
    });
  }

  void _next() {
    final nextIndex = _current + 1;
    if (nextIndex >= _exercises.length) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _current = nextIndex;
        _prepareExercise(_exercises[nextIndex]);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(widget.lessonTitle),
        centerTitle: true,
        actions: [
          if (!_loading && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  '${_current + 1} / ${_exercises.length}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? _emptyState()
              : _finished
                  ? _finishScreen()
                  : _exerciseBody(_exercises[_current]),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _progressBar() {
    final pct = _exercises.isEmpty
        ? 0.0
        : (_current + 1) / _exercises.length;
    return LinearProgressIndicator(
      value: pct,
      backgroundColor: AppTheme.border,
      color: AppTheme.primary,
      minHeight: 4,
    );
  }

  // ── Exercise body (dispatcher) ────────────────────────────────────────────

  Widget _exerciseBody(ExerciseModel ex) {
    return Column(
      children: [
        _progressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: switch (ex.type) {
              ExerciseType.SENTENCE_BUILDER => _sentenceBuilder(ex),
              _ => _multipleChoice(ex),
            },
          ),
        ),
        // Обратная связь + кнопка «Дальше»
        if (_submitted) _feedbackBar(),
      ],
    );
  }

  // ── Multiple choice (VOCABULARY, LISTENING, IMAGE_CONTEXT, AI_GENERATED) ─

  Widget _multipleChoice(ExerciseModel ex) {
    final question = ex.question ??
        ex.word ??
        'Выберите правильный вариант';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Изображение (если IMAGE_CONTEXT)
        if (ex.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              ex.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: AppTheme.border,
                child: const Icon(Icons.image_not_supported,
                    color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Аудиоплеер (если LISTENING)
        if (ex.type == ExerciseType.LISTENING && ex.audioUrl != null) ...[
          _audioPlayerWidget(ex.audioUrl!),
          const SizedBox(height: 18),
        ],

        Text(
          question,
          style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),

        if (ex.options.isEmpty)
          const Text('Нет вариантов ответа',
              style: TextStyle(color: AppTheme.textSecondary))
        else
          ...ex.options.map((opt) => _optionTile(opt)),

        // Объяснение после ответа
        if (_submitted && ex.explanation != null) ...[
          const SizedBox(height: 16),
          _explanationBox(ex.explanation!),
        ],
      ],
    );
  }

  // ── Audio player widget ───────────────────────────────────────────────────

  Widget _audioPlayerWidget(String audioUrl) {
    final isPlaying = _audioState == PlayerState.playing;
    return GestureDetector(
      onTap: () => _playAudio(audioUrl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.primary.withOpacity(0.12)
              : AppTheme.chipFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? AppTheme.primary : AppTheme.border,
            width: isPlaying ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isPlaying ? AppTheme.primary : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 3),
                    color: Color(0x1A000000),
                  ),
                ],
              ),
              child: Icon(
                isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'Воспроизводится...' : 'Нажмите для прослушивания',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isPlaying ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Аудирование',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(String opt) {
    Color? bgColor;
    Color borderColor = AppTheme.border;

    if (_submitted) {
      if (opt == _selectedOption) {
        bgColor = _lastCorrect == true
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE);
        borderColor = _lastCorrect == true
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350);
      }
    } else if (opt == _selectedOption) {
      bgColor = AppTheme.chipFill;
      borderColor = AppTheme.primary;
    }

    return GestureDetector(
      onTap: _submitted
          ? null
          : () {
              setState(() => _selectedOption = opt);
              _submit(opt);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(opt,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (_submitted && opt == _selectedOption)
              Icon(
                _lastCorrect == true ? Icons.check_circle : Icons.cancel,
                color: _lastCorrect == true
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Sentence builder ──────────────────────────────────────────────────────

  Widget _sentenceBuilder(ExerciseModel ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ex.question ?? 'Составьте предложение',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),

        // Собранное предложение
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _submitted
                  ? (_lastCorrect == true
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF5350))
                  : AppTheme.primary,
              width: 1.5,
            ),
          ),
          child: _chosenWords.isEmpty
              ? const Text('Нажмите на слова ниже...',
                  style: TextStyle(color: AppTheme.textSecondary))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _chosenWords
                      .map((w) => _wordChip(w, chosen: true))
                      .toList(),
                ),
          ),   // Container
        ),     // ConstrainedBox

        const SizedBox(height: 24),

        // Слова-источники
        if (!_submitted)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _remainingWords
                .map((w) => _wordChip(w, chosen: false))
                .toList(),
          ),

        // Кнопка «Проверить»
        if (!_submitted && _chosenWords.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  _submit(_chosenWords.join(' ')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Проверить'),
            ),
          ),
        ],

        if (_submitted && ex.explanation != null) ...[
          const SizedBox(height: 16),
          _explanationBox(ex.explanation!),
        ],
      ],
    );
  }

  Widget _wordChip(String word, {required bool chosen}) {
    return GestureDetector(
      onTap: _submitted
          ? null
          : () {
              setState(() {
                if (chosen) {
                  _chosenWords.remove(word);
                  _remainingWords.add(word);
                } else {
                  _remainingWords.remove(word);
                  _chosenWords.add(word);
                }
              });
            },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chosen ? AppTheme.chipFill : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chosen ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(word,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: chosen ? AppTheme.primary : AppTheme.textPrimary,
            )),
      ),
    );
  }

  // ── Feedback bar ──────────────────────────────────────────────────────────

  Widget _feedbackBar() {
    final correct = _lastCorrect == true;
    return Container(
      color: correct
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFEBEE),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: correct
                ? const Color(0xFF4CAF50)
                : const Color(0xFFEF5350),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              correct ? 'Верно!' : 'Неверно',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: correct
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: correct
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              _current + 1 < _exercises.length
                  ? 'Дальше'
                  : 'Завершить',
            ),
          ),
        ],
      ),
    );
  }

  // ── Explanation box ───────────────────────────────────────────────────────

  Widget _explanationBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              color: Color(0xFFFF8F00), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  // ── Finish screen ─────────────────────────────────────────────────────────

  Widget _finishScreen() {
    final total = _exercises.length;
    final pct = total > 0 ? (_correctCount / total * 100).round() : 0;
    final perfect = _correctCount == total;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              perfect ? Icons.emoji_events : Icons.check_circle_outline,
              color: AppTheme.primary,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              perfect ? 'Отлично!' : 'Урок завершён!',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '$_correctCount из $total правильно ($pct%)',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Вернуться назад',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined,
              color: AppTheme.textSecondary, size: 56),
          const SizedBox(height: 16),
          const Text('В этом уроке пока нет упражнений',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Назад',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

