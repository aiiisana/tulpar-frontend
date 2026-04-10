import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../features/lesson/exercise_screen.dart';
import '../services/lesson_service.dart';

// ── Canvas constants ──────────────────────────────────────────────────────────

const double kLevelMapWidth   = 420;
const double kMapCanvasPadding = 28;
const double kMapCanvasWidth  = kLevelMapWidth + kMapCanvasPadding * 2;

const double _kNodeStep = 130.0; // вертикальный шаг между пузырьками
const double _kFirstY  = 68.0;  // Y первого пузырька
const double _kBottomMargin = 80.0;

// ── Load result ───────────────────────────────────────────────────────────────

class _LoadResult {
  final List<_MapLesson> lessons;
  final bool needsLevelSelection;

  const _LoadResult({required this.lessons, required this.needsLevelSelection});

  factory _LoadResult.empty() =>
      const _LoadResult(lessons: [], needsLevelSelection: false);

  factory _LoadResult.needsSelection() =>
      const _LoadResult(lessons: [], needsLevelSelection: true);
}

// ── Internal data model ───────────────────────────────────────────────────────

class _MapLesson {
  final String? backendId;
  final int fallbackIndex;
  final String title;
  final bool unlocked;
  final bool completed;

  const _MapLesson({
    this.backendId,
    required this.fallbackIndex,
    required this.title,
    required this.unlocked,
    this.completed = false,
  });

  bool get isBackend => backendId != null;
}

// ── Position helpers ──────────────────────────────────────────────────────────

/// Зигзаг-позиции: чётные — правее, нечётные — левее
Offset _positionFor(int i) {
  final x = (i % 2 == 0)
      ? kLevelMapWidth * 0.58
      : kLevelMapWidth * 0.30;
  final y = _kFirstY + i * _kNodeStep;
  return Offset(x, y);
}

double _canvasHeight(int count) {
  if (count <= 0) return _kFirstY + _kBottomMargin;
  return _kFirstY + (count - 1) * _kNodeStep + _kBottomMargin;
}

List<Offset> _centers(int count) =>
    List.generate(count, (i) => _positionFor(i));

// ── Path painter ──────────────────────────────────────────────────────────────

enum _SegmentKind { locked, next, completed }

class _LevelPathPainter extends CustomPainter {
  final List<Offset> points;
  final List<_SegmentKind> kinds;

  _LevelPathPainter({required this.points, required this.kinds});

  static Path _segmentPath(Offset p0, Offset p1, int segIndex) {
    final mx = (p0.dx + p1.dx) / 2;
    final my = (p0.dy + p1.dy) / 2;
    final ctrl = Offset(mx + (segIndex.isEven ? 26 : -26), my);
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var s = 0; s < points.length - 1; s++) {
      final path = _segmentPath(points[s], points[s + 1], s);
      final kind = s < kinds.length ? kinds[s] : _SegmentKind.locked;

      late Color main;
      late double w;
      switch (kind) {
        case _SegmentKind.locked:
          main = const Color(0xFFB8C4BC).withOpacity(0.55);
          w = 6;
        case _SegmentKind.next:
          main = const Color(0xFFC9E85C);
          w = 11;
        case _SegmentKind.completed:
          main = AppTheme.primary;
          w = 10;
      }

      if (kind == _SegmentKind.next) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFE8F5A0).withOpacity(0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w + 6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = main
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter old) =>
      old.points != points || old.kinds != kinds;
}

// ── HomeLevelMap widget ───────────────────────────────────────────────────────

class HomeLevelMap extends StatefulWidget {
  const HomeLevelMap({super.key});

  /// Открыть первый доступный урок (вызывается кнопкой «Начать урок»).
  /// Берёт первый незавершённый урок с бэкенда; если бэк недоступен — показывает сообщение.
  static Future<void> openRecommendedLesson(BuildContext context) async {
    try {
      final courses = await LessonService.getCourses();
      if (courses.isEmpty) { _noLessonsSnack(context); return; }

      final levels = await LessonService.getCourseLevels(courses.first.id);

      if (levels.isEmpty) {
        // User has no difficulty selected — prompt them.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Сначала выберите уровень в настройках'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      // Backend returns exactly one level (the user's difficulty group).
      // Find the first unlocked-but-not-completed lesson.
      final lessons = levels.first.lessons;
      for (final lesson in lessons) {
        if (lesson.unlocked && !lesson.completed) {
          if (!context.mounted) return;
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ExerciseScreen(
                lessonId: lesson.id, lessonTitle: lesson.title),
          ));
          return;
        }
      }
      // All lessons completed — re-open the last one for review.
      if (lessons.isNotEmpty && context.mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => ExerciseScreen(
            lessonId: lessons.last.id,
            lessonTitle: lessons.last.title,
          ),
        ));
      }
    } catch (_) {
      if (context.mounted) _noLessonsSnack(context);
    }
  }

  static void _noLessonsSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Уроки недоступны. Проверьте подключение.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  State<HomeLevelMap> createState() => HomeLevelMapState();
}

class HomeLevelMapState extends State<HomeLevelMap> {
  List<_MapLesson> _lessons = [];
  bool _loading = true;
  /// True when the backend returned an empty level list because the user
  /// has not selected a difficulty level yet (onboarding incomplete).
  bool _needsLevelSelection = false;

  @override
  void initState() {
    super.initState();
    reloadProgress();
  }

  // ── Загрузка: сначала бэкенд, при неудаче — фоллбэк ─────────────────────

  Future<void> reloadProgress() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _needsLevelSelection = false;
    });

    final result = await _loadFromBackend();

    if (!mounted) return;
    setState(() {
      _lessons = result.lessons;
      _needsLevelSelection = result.needsLevelSelection;
      _loading = false;
    });
  }

  /// Loads lessons for the user's selected difficulty from the backend.
  ///
  /// Returns a [_LoadResult] with:
  /// - [_LoadResult.lessons] — the ordered list of map nodes (empty on error or no content)
  /// - [_LoadResult.needsLevelSelection] — true when the backend explicitly returned an empty
  ///   list because the user has not chosen a difficulty yet (vs. a network failure)
  Future<_LoadResult> _loadFromBackend() async {
    try {
      final courses = await LessonService.getCourses();
      if (courses.isEmpty) return _LoadResult.empty();

      final levels = await LessonService.getCourseLevels(courses.first.id);

      if (levels.isEmpty) {
        // Backend intentionally returns [] when the user has no difficulty set.
        // Signal the UI to show the "please select your level" prompt.
        return _LoadResult.needsSelection();
      }

      // The backend guarantees exactly ONE level group (the user's difficulty).
      // Never flatten across multiple groups — that would mix difficulties and
      // break sequential unlocking.
      final level = levels.first;
      final lessons = level.lessons;
      if (lessons.isEmpty) return _LoadResult.empty();

      return _LoadResult(
        lessons: lessons.map((lesson) => _MapLesson(
          backendId: lesson.id,
          fallbackIndex: lessons.indexOf(lesson) + 1,
          title: lesson.title,
          // Trust the backend's unlock flag completely.
          // Backend correctly marks the first lesson as unlocked and gates
          // subsequent lessons behind completing all exercises of the previous one.
          unlocked: lesson.unlocked,
          completed: lesson.completed,
        )).toList(),
        needsLevelSelection: false,
      );
    } catch (e) {
      debugPrint('[HomeLevelMap] _loadFromBackend error: $e');
      return _LoadResult.empty();
    }
  }

  // ── Сегменты пути ─────────────────────────────────────────────────────────

  List<_SegmentKind> _segmentKinds() {
    final kinds = <_SegmentKind>[];
    for (var s = 0; s < _lessons.length - 1; s++) {
      final curr = _lessons[s];
      if (!curr.unlocked) {
        kinds.add(_SegmentKind.locked);
      } else if (curr.completed) {
        kinds.add(_SegmentKind.completed);
      } else {
        kinds.add(_SegmentKind.next);
      }
    }
    return kinds;
  }

  // ── Тап на пузырёк ───────────────────────────────────────────────────────

  Future<void> _onNodeTap(_MapLesson lesson) async {
    if (!lesson.unlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала пройдите предыдущий урок'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    // All lessons now always come from the backend — backendId is always set.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseScreen(
          lessonId: lesson.backendId!,
          lessonTitle: lesson.title,
        ),
      ),
    );

    await reloadProgress();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 380,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_needsLevelSelection) {
      // User hasn't chosen a difficulty yet — guide them to onboarding.
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 48, color: AppTheme.primary.withOpacity(0.7)),
            const SizedBox(height: 12),
            const Text(
              'Выберите уровень',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Пройдите настройку, чтобы начать обучение',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return const SizedBox(height: 60);
    }

    const nodeSize = 72.0;
    const half = nodeSize / 2;
    final n = _lessons.length;
    final pts = _centers(n);
    final canvasH = _canvasHeight(n);
    final kinds = _segmentKinds();

    // Высота виджета: показываем максимум 3 пузырька + скролл
    final widgetHeight = n <= 3 ? canvasH + kMapCanvasPadding * 2 : 380.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widgetHeight,
        child: InteractiveViewer(
          alignment: Alignment.center,
          minScale: 0.75,
          maxScale: 1.55,
          boundaryMargin: const EdgeInsets.all(12),
          constrained: false,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: kMapCanvasWidth,
            height: canvasH + kMapCanvasPadding * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Фон
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFE8E9EC),
                          const Color(0xFFEBE8E0),
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Виньетка
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.85),
                          radius: 1.15,
                          colors: [
                            Colors.white.withOpacity(0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.65],
                        ),
                      ),
                    ),
                  ),
                ),
                // Пути + узлы
                Positioned(
                  left: kMapCanvasPadding,
                  top: kMapCanvasPadding,
                  width: kLevelMapWidth,
                  height: canvasH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Линии-пути
                      CustomPaint(
                        size: Size(kLevelMapWidth, canvasH),
                        painter: _LevelPathPainter(points: pts, kinds: kinds),
                      ),
                      // Пузырьки уроков
                      for (var i = 0; i < _lessons.length; i++)
                        Positioned(
                          left: pts[i].dx - half,
                          top: pts[i].dy - half,
                          width: nodeSize,
                          height: nodeSize,
                          child: _NodeBubble(
                            lesson: _lessons[i],
                            index: i,
                            onTap: () => _onNodeTap(_lessons[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Пузырёк урока ─────────────────────────────────────────────────────────────

class _NodeBubble extends StatelessWidget {
  final _MapLesson lesson;
  final int index;
  final VoidCallback onTap;

  const _NodeBubble({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked    = !lesson.unlocked;
    final completed = lesson.completed;

    final Color borderColor;
    final double borderW;
    final Color bgColor;

    if (locked) {
      borderColor = AppTheme.border;
      borderW     = 2.0;
      bgColor     = Colors.white;
    } else if (completed) {
      borderColor = AppTheme.primary;
      borderW     = 3.0;
      bgColor     = AppTheme.primary.withOpacity(0.08);
    } else {
      borderColor = const Color(0xFFC9E85C);
      borderW     = 3.0;
      bgColor     = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor, width: borderW),
              boxShadow: [
                if (!locked)
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 0,
                    color: (completed ? AppTheme.primary : const Color(0xFFC9E85C))
                        .withOpacity(0.35),
                  ),
                const BoxShadow(
                  blurRadius: 10,
                  offset: Offset(0, 5),
                  color: Color(0x18000000),
                ),
              ],
            ),
            child: Center(
              child: locked
                  ? Icon(Icons.lock_outline,
                      color: AppTheme.primary.withOpacity(0.65), size: 26)
                  : completed
                      ? const Icon(Icons.check_rounded,
                          color: AppTheme.primary, size: 30)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Icon(Icons.star_rounded,
                                color: Color(0xFF8FAF3A), size: 22),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
