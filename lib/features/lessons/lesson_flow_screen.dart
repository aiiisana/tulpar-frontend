import 'dart:math';

import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/theme.dart';
import '../../models/level_map_node.dart';
import '../../widgets/circle_back_button.dart';

class LessonFlowScreen extends StatefulWidget {
  final int lessonIndex;
  final String title;
  final String subtitleKk;
  final String description;

  const LessonFlowScreen({
    super.key,
    required this.lessonIndex,
    required this.title,
    required this.subtitleKk,
    required this.description,
  });

  static Future<void> open(BuildContext context, LevelMapNode node) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LessonFlowScreen(
          lessonIndex: node.lessonIndex,
          title: node.title,
          subtitleKk: node.subtitleKk,
          description: node.description,
        ),
      ),
    );
  }

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  late final List<_LessonStepSpec> _steps;
  int _index = 0;
  int? _mcqFeedback;
  final _typeCtrl = TextEditingController();
  final List<String> _letterSlots = [];
  List<String> _letterPool = [];

  static String _keywordForLesson(int lessonIndex) {
    switch (lessonIndex) {
      case 1:
        return 'Сәлем';
      case 2:
        return 'Танысу';
      case 3:
        return 'Отбасы';
      case 4:
        return 'Қалада';
      case 5:
        return 'Тамақ';
      default:
        return 'Сәлем';
    }
  }

  static List<String> _mcqOptionsForLesson(int lessonIndex) {
    switch (lessonIndex) {
      case 1:
        return ['Сәлем', 'Салам', 'Сәлім'];
      case 2:
        return ['Танысу', 'Тансу', 'Танышу'];
      case 3:
        return ['Отбасы', 'Ата-ана', 'Үй'];
      case 4:
        return ['Қалада', 'Қала', 'Жолда'];
      case 5:
        return ['Тамақ', 'Су', 'Нан'];
      default:
        return ['Сәлем', 'Салам', 'Сәлім'];
    }
  }

  @override
  void initState() {
    super.initState();
    _steps = _buildStepsForLesson(widget.lessonIndex);
  }

  void _initLettersIfNeeded(String target) {
    _letterPool = target.runes.map((r) => String.fromCharCode(r)).toList()..shuffle(Random());
    _letterSlots.clear();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  int get _taskSteps => _steps.where((s) => s.kind != _StepKind.completion).length;

  int get _progressIndex {
    if (_index >= _steps.length) return _taskSteps;
    if (_steps[_index].kind == _StepKind.completion) return _taskSteps;
    return _index.clamp(0, _taskSteps);
  }

  double get _progress => _taskSteps == 0 ? 1.0 : (_progressIndex + 1) / _taskSteps;

  List<_LessonStepSpec> _buildStepsForLesson(int lessonIndex) {
    final kw = _keywordForLesson(lessonIndex);

    // Ровно 3 вопроса + экран завершения
    return [
      // Вопрос 1: выбор правильного слова
      _LessonStepSpec(
        kind: _StepKind.mcqListen,
        title: 'Выбери правильный вариант',
        subtitle: 'Какое слово переводится как «${widget.title}»?',
        options: _mcqOptionsForLesson(lessonIndex),
        correctIndex: 0,
      ),
      // Вопрос 2: собери слово по буквам
      _LessonStepSpec(
        kind: _StepKind.letters,
        title: 'Собери слово по буквам',
        subtitle: 'Расставь буквы в правильном порядке',
        expectedWord: kw,
      ),
      // Вопрос 3: напиши слово
      _LessonStepSpec(
        kind: _StepKind.typeWord,
        title: 'Напиши слово',
        subtitle: 'Введи казахское слово для «${widget.title}»',
        expectedWord: kw,
      ),
      const _LessonStepSpec(kind: _StepKind.completion),
    ];
  }

  void _goNext() {
    if (_index >= _steps.length - 1) return;
    setState(() {
      _index++;
      _mcqFeedback = null;
      if (_index < _steps.length && _steps[_index].kind == _StepKind.letters) {
        final w = _steps[_index].expectedWord;
        if (w != null) _initLettersIfNeeded(w);
      }
      if (_index < _steps.length && _steps[_index].kind == _StepKind.typeWord) {
        _typeCtrl.clear();
      }
    });
  }

  void _onMcqTap(int i, _LessonStepSpec spec) {
    if (_mcqFeedback != null) return;
    if (i == spec.correctIndex) {
      setState(() => _mcqFeedback = 1);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _goNext();
      });
    } else {
      setState(() => _mcqFeedback = -1);
    }
  }

  void _dismissWrongOverlay() {
    if (_mcqFeedback == -1) setState(() => _mcqFeedback = null);
  }

  void _tapLetterPool(String ch) {
    final target = _steps[_index].expectedWord ?? '';
    if (target.isEmpty || _letterSlots.length >= target.length) return;
    final idx = _letterPool.indexOf(ch);
    if (idx < 0) return;
    setState(() {
      _letterPool.removeAt(idx);
      _letterSlots.add(ch);
    });
  }

  void _letterBackspace() {
    if (_letterSlots.isEmpty) return;
    setState(() {
      final last = _letterSlots.removeLast();
      _letterPool.add(last);
    });
  }

  void _checkTypedWord(String expected) {
    final a = _typeCtrl.text.trim();
    if (a == expected) {
      _goNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Попробуй ещё раз')),
      );
    }
  }

  void _checkLetters() {
    final target = _steps[_index].expectedWord ?? '';
    if (_letterSlots.join() == target) {
      _goNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Собери слово «$target»')),
      );
    }
  }

  Future<void> _finishLesson() async {
    await AppStorage.markLessonCompleted(widget.lessonIndex);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _steps[_index];
    final lessonTitle = 'Урок ${widget.lessonIndex}: «${widget.title}»';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      lessonTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            if (spec.kind != _StepKind.completion) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ),
            ],
            Expanded(
              child: _buildStepBody(spec),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(_LessonStepSpec spec) {
    switch (spec.kind) {
      case _StepKind.listenIntro:
        return _wrapFeedback(
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(spec.title, style: _titleStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(spec.subtitle, style: _subStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        _LessonAudioButton(onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: OutlinedButton(
                  onPressed: _goNext,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Text(
                    widget.lessonIndex == 1 ? 'Сәлем = Привет' : 'Дальше',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      case _StepKind.mcqListen:
        return _wrapFeedback(_mcqStack(spec));
      case _StepKind.repeat:
        return _wrapFeedback(
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(spec.title, style: _titleStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(spec.subtitle, style: _subStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        _LessonAudioButton(onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: OutlinedButton(
                  onPressed: _goNext,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Я повторил', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      case _StepKind.letters:
        return Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(spec.title, style: _titleStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(spec.subtitle, style: _subStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Center(child: _LessonAudioButton(onPressed: () {})),
                      const SizedBox(height: 20),
                      Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _letterSlots.join(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final ch in _letterPool)
                            ActionChip(
                              label: Text(ch, style: const TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: () => _tapLetterPool(ch),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _letterBackspace,
                        icon: const Icon(Icons.backspace_outlined, size: 20),
                        label: const Text('Удалить букву'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: _checkLetters,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Проверить', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      case _StepKind.typeWord:
        return Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(spec.title, style: _titleStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(spec.subtitle, style: _subStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Center(child: _LessonAudioButton(onPressed: () {})),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _typeCtrl,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: spec.expectedWord,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: () => _checkTypedWord(spec.expectedWord ?? ''),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Проверить', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      case _StepKind.completion:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Молодец!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/girl.png',
                height: 350,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Поздравляем! Вы справились с уроком!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
              ),
              const SizedBox(height: 10),
              Text(
                'Отлично справляешься, продолжай в том же духе!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.primary.withOpacity(0.85), height: 1.35),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _finishLesson,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Главный экран', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
    }
  }

  Widget _wrapFeedback(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (_mcqFeedback == 1)
          Positioned.fill(
            child: Container(
              color: Colors.green.withOpacity(0.38),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 72, color: Colors.green.shade800),
                  const SizedBox(height: 12),
                  Text(
                    'Верно! Так держать!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        if (_mcqFeedback == -1)
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissWrongOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.red.withOpacity(0.32),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 72, color: Colors.red.shade800),
                    const SizedBox(height: 12),
                    Text(
                      'Почти! Попробуй ещё раз',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нажми, чтобы продолжить',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade900.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mcqStack(_LessonStepSpec spec) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(spec.title, style: _titleStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(spec.subtitle, style: _subStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  _LessonAudioButton(onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < (spec.options?.length ?? 0); i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: () => _onMcqTap(i, spec),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: Text(spec.options![i], style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static const _titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w800);
  static final _subStyle = TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.35);
}

enum _StepKind {
  listenIntro,
  mcqListen,
  repeat,
  letters,
  typeWord,
  completion,
}

class _LessonStepSpec {
  final _StepKind kind;
  final String title;
  final String subtitle;
  final List<String>? options;
  final int? correctIndex;
  final String? expectedWord;

  const _LessonStepSpec({
    required this.kind,
    this.title = '',
    this.subtitle = '',
    this.options,
    this.correctIndex,
    this.expectedWord,
  });
}

class _LessonAudioButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LessonAudioButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.volume_up_outlined, size: 34, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
