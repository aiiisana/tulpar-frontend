import 'package:audioplayers/audioplayers.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme.dart';
import '../../services/lesson_service.dart';
import '../../services/progress_service.dart';

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
  bool _prevCorrect = false; // результат предыдущего задания
  int _correctCount = 0;
  bool _finished = false;

  List<String> _chosenWords = [];
  List<String> _remainingWords = [];
  String? _selectedOption;

  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _audioState = PlayerState.stopped;

  VideoPlayerController? _videoController;
  ChewieController?      _chewieController;
  bool _videoInitializing = false;
  String? _videoError;

  int _lastXpEarned = 0;
  String? _lastCorrectAnswer;

  @override
  void initState() {
    super.initState();
    _load();
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _audioState = s);
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
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController  = null;
  }

  void _prepareExercise(ExerciseModel ex) {
    _submitted = false;
    _lastCorrect = null;
    _lastCorrectAnswer = null;
    _selectedOption = null;
    _audioPlayer.stop();
    _audioState = PlayerState.stopped;
    _disposeVideo();
    _videoError = null;

    if (ex.type == ExerciseType.SENTENCE_BUILDER) {
      _remainingWords = List.from(ex.shuffledWords);
      _chosenWords = [];
    }
    if (ex.type == ExerciseType.VIDEO_CONTEXT && ex.videoUrl != null) {
      _initVideo(ex.videoUrl!);
    }
  }

  Future<void> _initVideo(String rawUrl) async {
    final url = _resolveUrl(rawUrl);
    setState(() { _videoInitializing = true; _videoError = null; });
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true, looping: false,
        allowFullScreen: true, allowMuting: true,
        showControlsOnInitialize: false,
        aspectRatio: controller.value.aspectRatio,
      );
      setState(() {
        _videoController   = controller;
        _chewieController  = chewie;
        _videoInitializing = false;
      });
    } catch (e) {
      debugPrint('[Video] $e');
      if (!mounted) return;
      setState(() { _videoInitializing = false; _videoError = 'Не удалось загрузить видео'; });
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080/api');
    return '$base$url';
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_audioState == PlayerState.playing) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(UrlSource(_resolveUrl(url)));
      }
    } catch (e) { debugPrint('[Audio] $e'); }
  }

  Future<void> _submit(String answer) async {
    if (_submitted) return;
    setState(() => _submitted = true);

    final ex = _exercises[_current];
    final result = await ProgressService.submit(exerciseId: ex.id, userAnswer: answer);

    if (!mounted) return;
    setState(() {
      _lastCorrect       = result?.correct ?? false;
      _lastXpEarned      = result?.xpEarned ?? 0;
      _lastCorrectAnswer = result?.correctAnswer;
      if (_lastCorrect == true) _correctCount++;
    });
  }

  void _next() {
    final next = _current + 1;
    final wasCorrect = _lastCorrect == true;
    if (next >= _exercises.length) {
      setState(() {
        _prevCorrect = wasCorrect;
        _finished = true;
      });
    } else {
      setState(() {
        _prevCorrect = wasCorrect;
        _current = next;
        _prepareExercise(_exercises[next]);
      });
    }
  }

  // ── Colors ────────────────────────────────────────────────────────────────

  static const _greenBg   = Color(0xFFA8E6AF);
  static const _redBg     = Color(0xFFF0A0A0);
  static const _greenText = Color(0xFF2D8B2D);
  static const _redText   = Color(0xFFCC2222);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _exercises.isEmpty
                ? _emptyState()
                : _finished
                    ? _finishScreen()
                    : _exerciseBody(_exercises[_current]),
      ),
    );
  }

  // ── Exercise body ─────────────────────────────────────────────────────────

  Widget _exerciseBody(ExerciseModel ex) {
    final heading = ex.question ?? _defaultHeading(ex.type);

    final resultKnown = _submitted && _lastCorrect != null;
    final bgColor = resultKnown
        ? (_lastCorrect == true ? _greenBg : _redBg)
        : AppTheme.background;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      color: bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Faded content layer ──────────────────────────────────────────
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: resultKnown ? 0.3 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),

                  // Question (above progress bar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Text(
                      heading,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                  ),

                  _progressBar(),

                  // Scrollable exercise content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: _submitted
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: switch (ex.type) {
                        ExerciseType.SENTENCE_BUILDER => _sentenceBuilder(ex),
                        ExerciseType.VIDEO_CONTEXT    => _videoExercise(ex),
                        _                             => _multipleChoice(ex),
                      },
                    ),
                  ),


                ],
              ),
            ),
          ),

          // ── Feedback overlay (after answer) ──────────────────────────────
          if (_submitted && _lastCorrect != null) _feedbackOverlay(),
        ],
      ),
    );
  }

  String _defaultHeading(ExerciseType type) => switch (type) {
    ExerciseType.SENTENCE_BUILDER => 'Составь предложение',
    ExerciseType.LISTENING        => 'Выбери правильный ответ',
    ExerciseType.VOCABULARY       => 'Выбери значение слова',
    _                             => 'Выбери правильный ответ',
  };

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEDE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left,
                    color: AppTheme.textPrimary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.lessonTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${_current + 1}/${_exercises.length}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _progressBar() {
    final pct = _exercises.isEmpty ? 0.0 : (_current + 1) / _exercises.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFFDDDDD5),
          color: AppTheme.primary,
          minHeight: 8,
        ),
      ),
    );
  }

  // ── Tulpar horse ──────────────────────────────────────────────────────────

  Widget _tulparImage() {
    final asset = _prevCorrect
        ? 'assets/images/happy_tulpar.png'
        : 'assets/images/tulpar.png';
    return SizedBox(
      height: 200,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  // ── Feedback overlay ──────────────────────────────────────────────────────

  Widget _feedbackOverlay() {
    final correct     = _lastCorrect == true;
    final color       = correct ? _greenText : _redText;
    final icon        = correct ? Icons.check_rounded : Icons.close_rounded;
    final message     = correct ? 'Верно! Так держать!' : 'Почти! Попробуй ещё раз';
    final label       = _current + 1 < _exercises.length ? 'Дальше' : 'Завершить';
    final showCorrect = !correct &&
        _lastCorrectAnswer != null &&
        _lastCorrectAnswer!.isNotEmpty;

    return Column(
      children: [
        const Spacer(flex: 3),
        // Big result icon
        Icon(icon, size: 130, color: color),
        const SizedBox(height: 14),
        // Message
        Text(
          message,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        // XP badge (correct answer)
        if (correct && _lastXpEarned > 0) ...[
          const SizedBox(height: 8),
          Text('+$_lastXpEarned XP',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
        // Correct answer hint (wrong answer)
        if (showCorrect) ...[
          const SizedBox(height: 8),
          Text(
            'Правильный ответ: $_lastCorrectAnswer',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
        // Horse image
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Image.asset(
            correct
                ? 'assets/images/happy_tulpar.png'
                : 'assets/images/tulpar.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const Spacer(flex: 2),
        // Next button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Multiple choice ───────────────────────────────────────────────────────

  Widget _multipleChoice(ExerciseModel ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Изображение (IMAGE_CONTEXT)
        if (ex.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              _resolveUrl(ex.imageUrl!),
              height: 180, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180, color: AppTheme.border,
                child: const Icon(Icons.image_not_supported,
                    color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // LISTENING: подсказка + кнопка аудио
        if (ex.type == ExerciseType.LISTENING && ex.audioUrl != null) ...[
          Text(
            'Прослушай аудио и выбери то, что ты слышишь',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),
          _audioCircleButton(ex.audioUrl!),
          const SizedBox(height: 24),
        ],

        // Варианты ответа
        if (ex.options.isEmpty)
          const Text('Нет вариантов ответа',
              style: TextStyle(color: AppTheme.textSecondary))
        else
          ...ex.options.map((opt) => _optionTile(opt)),

        if (_submitted && ex.explanation != null) ...[
          const SizedBox(height: 16),
          _explanationBox(ex.explanation!),
        ],
      ],
    );
  }

  // ── Audio circle button ───────────────────────────────────────────────────

  Widget _audioCircleButton(String audioUrl) {
    final playing = _audioState == PlayerState.playing;
    return Center(
      child: GestureDetector(
        onTap: () => _playAudio(audioUrl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: playing ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: playing ? AppTheme.primary : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x14000000)),
            ],
          ),
          child: Icon(
            playing ? Icons.stop_rounded : Icons.volume_up_rounded,
            color: AppTheme.primary, size: 28,
          ),
        ),
      ),
    );
  }

  // ── Option tile (pill) ────────────────────────────────────────────────────

  Widget _optionTile(String opt) {
    Color? bgColor;
    Color borderColor = AppTheme.border;

    // Применяем цвет результата только когда ответ уже получен
    final resultKnown = _submitted && _lastCorrect != null;

    if (resultKnown) {
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
          : () { setState(() => _selectedOption = opt); _submit(opt); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(opt,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            if (resultKnown && opt == _selectedOption) ...[
              const SizedBox(width: 8),
              Icon(
                _lastCorrect == true ? Icons.check_circle : Icons.cancel,
                color: _lastCorrect == true
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Video exercise ────────────────────────────────────────────────────────

  Widget _videoExercise(ExerciseModel ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
            child: _videoInitializing
                ? Container(color: Colors.black,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)))
                : _videoError != null
                    ? Container(
                        color: Colors.black87,
                        child: Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                            const SizedBox(height: 10),
                            Text(_videoError!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        )))
                    : _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : Container(color: Colors.black,
                            child: const Center(child: CircularProgressIndicator(color: Colors.white))),
          ),
        ),
        const SizedBox(height: 20),
        if (ex.options.isEmpty)
          const Text('Нет вариантов ответа',
              style: TextStyle(color: AppTheme.textSecondary))
        else
          ...ex.options.map((opt) => _optionTile(opt)),
        if (_submitted && ex.explanation != null) ...[
          const SizedBox(height: 16),
          _explanationBox(ex.explanation!),
        ],
      ],
    );
  }

  // ── Sentence builder ──────────────────────────────────────────────────────

  Widget _sentenceBuilder(ExerciseModel ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    ? (_lastCorrect == true ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
                    : AppTheme.primary,
                width: 1.5,
              ),
            ),
            child: _chosenWords.isEmpty
                ? const Text('Нажмите на слова ниже...',
                    style: TextStyle(color: AppTheme.textSecondary))
                : Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _chosenWords
                        .map((w) => _wordChip(w, chosen: true))
                        .toList(),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        if (!_submitted)
          Wrap(spacing: 8, runSpacing: 8,
              children: _remainingWords.map((w) => _wordChip(w, chosen: false)).toList()),
        if (!_submitted && _chosenWords.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(_chosenWords.join(' ')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Проверить',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chosen ? AppTheme.chipFill : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chosen ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(word,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: chosen ? AppTheme.primary : AppTheme.textPrimary)),
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
          const Icon(Icons.lightbulb_outline, color: Color(0xFFFF8F00), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  // ── Finish screen ─────────────────────────────────────────────────────────

  Widget _finishScreen() {
    final total   = _exercises.length;
    final pct     = total > 0 ? (_correctCount / total * 100).round() : 0;
    final perfect = _correctCount == total;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              perfect ? 'assets/images/happy_tulpar.png' : 'assets/images/tulpar.png',
              height: 160,
              errorBuilder: (_, __, ___) => Icon(
                perfect ? Icons.emoji_events : Icons.check_circle_outline,
                color: AppTheme.primary, size: 80,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              perfect ? 'Отлично!' : 'Урок завершён!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '$_correctCount из $total правильно ($pct%)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
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
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Вернуться назад',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Назад', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
