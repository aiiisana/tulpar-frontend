import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../features/lesson/exercise_screen.dart';
import '../services/lesson_service.dart';
import 'default_popup.dart';

// ── Canvas constants ──────────────────────────────────────────────────────────

const double kLevelMapWidth = 420;
const double kMapCanvasPadding = 28;
const double kMapCanvasWidth = kLevelMapWidth + kMapCanvasPadding * 2;

const double _kNodeStep = 130.0;
const double _kFirstY = 68.0;
const double _kBottomMargin = 80.0;

// ── Background constants ──────────────────────────────────────────────────────

const double _kBgBlockHeight = 400.0;
const String _kBg1 = 'assets/images/background.png';
const String _kBg2 = 'assets/images/background-2.png';

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
  final x = (i % 2 == 0) ? kLevelMapWidth * 0.70 : kLevelMapWidth * 0.20;
  final y = _kFirstY + i * _kNodeStep;
  return Offset(x, y);
}

double _canvasHeight(int count) {
  if (count <= 0) return _kFirstY + _kBottomMargin;
  return _kFirstY + (count - 1) * _kNodeStep + _kBottomMargin;
}

List<Offset> _centers(int count) =>
    List.generate(count, (i) => _positionFor(i));

Offset _getBezierPoint(Offset p0, Offset p1, double t, int segIndex) {
  final mx = (p0.dx + p1.dx) / 2;
  final my = (p0.dy + p1.dy) / 2;
  final ctrl = Offset(mx + (segIndex.isEven ? 50 : -50), my);
  double x =
      (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * ctrl.dx + t * t * p1.dx;
  double y =
      (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * ctrl.dy + t * t * p1.dy;
  return Offset(x, y);
}

// ── Path painter ──────────────────────────────────────────────────────────────

enum _SegmentKind { locked, next, completed }

class _LevelPathPainter extends CustomPainter {
  final List<Offset> points;
  final List<_MapLesson> lessons;
  final ui.Image? horseLeft;
  final ui.Image? horseRight;

  _LevelPathPainter({
    required this.points,
    required this.lessons,
    this.horseLeft,
    this.horseRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    for (var s = 0; s < points.length - 1; s++) {
      final p0 = points[s];
      final p1 = points[s + 1];
      final path = _segmentPath(p0, p1, s);

      final currentLesson = lessons[s];
      final nextLesson = lessons[s + 1];

      paintLine.color = currentLesson.completed
          ? const Color(0xFF3D523E)
          : const Color(0xFFB8C4BC).withOpacity(0.5);

      canvas.drawPath(path, paintLine);

      if (currentLesson.completed &&
          (nextLesson.unlocked && !nextLesson.completed)) {
        _drawHorseImage(canvas, p0, p1, s);
      }
    }
  }

  void _drawHorseImage(Canvas canvas, Offset p0, Offset p1, int index) {
    const double t = 0.5;
    final horsePos = _getBezierPoint(p0, p1, t, index);
    double angle = _getBezierAngle(p0, p1, t, index);

    final bool isHorseRight = (index % 2 == 0);
    final ui.Image? image = isHorseRight ? horseLeft : horseRight;

    if (image != null) {
      const double imgSize = 65.0;

      canvas.save();
      canvas.translate(horsePos.dx, horsePos.dy - 30);

      if (isHorseRight) {
        if (angle > 0) angle -= math.pi;
      } else {
        if (angle.abs() > math.pi / 2) angle += math.pi;
      }

      angle *= 0.45;

      canvas.rotate(angle);

      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: Offset.zero,
          width: imgSize,
          height: imgSize,
        ),
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );

      canvas.restore();
    }
  }

  double _getBezierAngle(Offset p0, Offset p1, double t, int segIndex) {
    final mx = (p0.dx + p1.dx) / 2;
    final my = (p0.dy + p1.dy) / 2;
    final ctrl = Offset(mx + (segIndex.isEven ? 50 : -50), my);

    final dx = 2 * (1 - t) * (ctrl.dx - p0.dx) + 2 * t * (p1.dx - ctrl.dx);
    final dy = 2 * (1 - t) * (ctrl.dy - p0.dy) + 2 * t * (p1.dy - ctrl.dy);

    return ui.Offset(dx, dy).direction;
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter old) => true;

  Offset _getBezierPoint(Offset p0, Offset p1, double t, int segIndex) {
    final mx = (p0.dx + p1.dx) / 2;
    final my = (p0.dy + p1.dy) / 2;
    final ctrl = Offset(mx + (segIndex.isEven ? 50 : -50), my);
    double x =
        (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * ctrl.dx + t * t * p1.dx;
    double y =
        (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * ctrl.dy + t * t * p1.dy;
    return Offset(x, y);
  }

  static Path _segmentPath(Offset p0, Offset p1, int segIndex) {
    final mx = (p0.dx + p1.dx) / 2;
    final my = (p0.dy + p1.dy) / 2;
    final ctrl = Offset(mx + (segIndex.isEven ? 50 : -50), my);
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
  }
}

// ── HomeLevelMap widget ───────────────────────────────────────────────────────

class HomeLevelMap extends StatefulWidget {
  const HomeLevelMap({super.key});

  /// Открыть первый доступный урок (вызывается кнопкой «Начать урок»).
  /// Берёт первый незавершённый урок с бэкенда; если бэк недоступен — показывает сообщение.
  static Future<void> openRecommendedLesson(BuildContext context) async {
    try {
      final courses = await LessonService.getCourses();
      if (courses.isEmpty) {
        _noLessonsSnack(context);
        return;
      }

      final levels = await LessonService.getCourseLevels(courses.first.id);

      if (levels.isEmpty) {
        // User has no difficulty selected — prompt them.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сначала выберите уровень в настройках'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Backend returns exactly one level (the user's difficulty group).
      // Find the first unlocked-but-not-completed lesson.
      final lessons = levels.first.lessons;
      for (final lesson in lessons) {
        if (lesson.unlocked && !lesson.completed) {
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseScreen(
                lessonId: lesson.id,
                lessonTitle: lesson.title,
              ),
            ),
          );
          return;
        }
      }
      // All lessons completed — re-open the last one for review.
      if (lessons.isNotEmpty && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseScreen(
              lessonId: lessons.last.id,
              lessonTitle: lessons.last.title,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) _noLessonsSnack(context);
    }
  }

  static void _noLessonsSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Уроки недоступны. Проверьте подключение.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  State<HomeLevelMap> createState() => HomeLevelMapState();
}

class HomeLevelMapState extends State<HomeLevelMap> {
  ui.Image? _horseRight;
  ui.Image? _horseLeft;
  List<_MapLesson> _lessons = [];
  bool _loading = true;

  /// True when the backend returned an empty level list because the user
  /// has not selected a difficulty level yet (onboarding incomplete).
  bool _needsLevelSelection = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    reloadProgress();
  }

  Future<void> _loadImages() async {
    _horseRight = await _loadImageAsset('assets/images/Vector.png');
    _horseLeft = await _loadImageAsset('assets/images/Vector-2.png');
    if (mounted) setState(() {});
  }

  Future<ui.Image> _loadImageAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

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
        lessons: lessons
            .map(
              (lesson) => _MapLesson(
                backendId: lesson.id,
                fallbackIndex: lessons.indexOf(lesson) + 1,
                title: lesson.title,
                // Trust the backend's unlock flag completely.
                // Backend correctly marks the first lesson as unlocked and gates
                // subsequent lessons behind completing all exercises of the previous one.
                unlocked: lesson.unlocked,
                completed: lesson.completed,
              ),
            )
            .toList(),
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
      // ЗАМЕНА: Теперь вызываем твой кастомный попап
      DefaultPopup.show(
        context,
        message: 'Сначала пройдите предыдущий уровень, чтобы открыть этот!',
        buttonText: 'Хорошо',
      );
      return;
    }

    if (!mounted) return;

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
            Icon(
              Icons.school_outlined,
              size: 48,
              color: AppTheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Выберите уровень',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Пройдите настройку, чтобы начать обучение',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
    final totalH = canvasH + kMapCanvasPadding * 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 380,
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            height: totalH,
            child: Stack(
              children: [
                // ── Repeating background ─────────────────────────────────
                _RepeatingBackground(totalHeight: totalH),

                // ── Level map content ────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: kLevelMapWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: kMapCanvasPadding,
                          width: kLevelMapWidth,
                          height: canvasH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                size: Size(kLevelMapWidth, canvasH),
                                painter: _LevelPathPainter(
                                  points: pts,
                                  lessons: _lessons,
                                  horseRight: _horseRight,
                                  horseLeft: _horseLeft,
                                ),
                              ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Repeating background ──────────────────────────────────────────────────────

class _RepeatingBackground extends StatelessWidget {
  final double totalHeight;

  const _RepeatingBackground({required this.totalHeight});

  @override
  Widget build(BuildContext context) {
    final int count = (totalHeight / _kBgBlockHeight).ceil() + 1;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, i) {
        final bool isEven = i.isEven;
        return SizedBox(
          height: _kBgBlockHeight,
          width: double.infinity,
          child: Image.asset(
            isEven ? _kBg2 : _kBg1,
            scale: 1.5,
            repeat: ImageRepeat.noRepeat,
            alignment: isEven ? Alignment.centerLeft : Alignment.centerRight,
          ),
        );
      },
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
    final bool isCompleted = lesson.completed;
    final bool isAvailable = lesson.unlocked && !lesson.completed;
    final bool isLocked = !lesson.unlocked;

    Color bgColor;
    Color textColor = Colors.white;
    if (isCompleted) {
      bgColor = const Color(0xFF3D523E); // Темно-зеленый
    } else if (isAvailable) {
      bgColor = const Color(0xFFC2D1B2); // Светло-зеленый
    } else {
      bgColor = const Color(0xFFD1D1D1); // Серый для закрытых
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Icon(
              isCompleted ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
