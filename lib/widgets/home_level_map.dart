import 'package:flutter/material.dart';
import '../app/app_storage.dart';
import '../app/theme.dart';
import '../features/lesson/exercise_screen.dart';
import '../features/lessons/lesson_flow_screen.dart';
import '../models/level_map_node.dart';
import '../services/lesson_service.dart';

// ── Canvas constants ──────────────────────────────────────────────────────────

const double kLevelMapWidth   = 420;
const double kMapCanvasPadding = 28;
const double kMapCanvasWidth  = kLevelMapWidth + kMapCanvasPadding * 2;

const double _kNodeStep = 130.0; // вертикальный шаг между пузырьками
const double _kFirstY  = 68.0;  // Y первого пузырька
const double _kBottomMargin = 80.0;

// ── Internal data model ───────────────────────────────────────────────────────

class _MapLesson {
  /// null = оффлайн-фоллбэк, non-null = реальный урок с бэкенда
  final String? backendId;
  final int fallbackIndex;   // используется только при backendId == null
  final String title;
  final String subtitleKk;
  final String description;
  final bool unlocked;

  const _MapLesson({
    this.backendId,
    required this.fallbackIndex,
    required this.title,
    required this.subtitleKk,
    required this.description,
    required this.unlocked,
  });

  bool get isBackend => backendId != null;
}

// ── Fallback 3 lessons ────────────────────────────────────────────────────────

const List<LevelMapNode> _kFallback = [
  LevelMapNode(
    lessonIndex: 1,
    title: 'Привет!',
    subtitleKk: 'Сәлем!',
    description: 'Первые фразы приветствия и прощания.',
    center: Offset.zero, // пересчитывается динамически
  ),
  LevelMapNode(
    lessonIndex: 2,
    title: 'Знакомство',
    subtitleKk: 'Танысу',
    description: 'Как представиться, спросить имя.',
    center: Offset.zero,
  ),
  LevelMapNode(
    lessonIndex: 3,
    title: 'Семья',
    subtitleKk: 'Отбасы',
    description: 'Слова про семью: әке, ана, аға.',
    center: Offset.zero,
  ),
];

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

  /// Открыть первый доступный урок (вызывается кнопкой «Начать урок»)
  static Future<void> openRecommendedLesson(BuildContext context) async {
    final done = await AppStorage.getCompletedLessons();
    for (final node in _kFallback) {
      if (done.contains(node.lessonIndex)) continue;
      if (await AppStorage.isLessonUnlocked(node.lessonIndex)) {
        await LessonFlowScreen.open(context, node);
        return;
      }
    }
    await LessonFlowScreen.open(context, _kFallback.last);
  }

  @override
  State<HomeLevelMap> createState() => HomeLevelMapState();
}

class HomeLevelMapState extends State<HomeLevelMap> {
  List<_MapLesson> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reloadProgress();
  }

  // ── Загрузка: сначала бэкенд, при неудаче — фоллбэк ─────────────────────

  Future<void> reloadProgress() async {
    if (!mounted) return;
    setState(() => _loading = true);

    List<_MapLesson> lessons = await _loadFromBackend();

    if (lessons.isEmpty) {
      lessons = await _buildFallback();
    }

    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
  }

  Future<List<_MapLesson>> _loadFromBackend() async {
    try {
      final courses = await LessonService.getCourses();
      if (courses.isEmpty) return [];

      final levels = await LessonService.getCourseLevels(courses.first.id);
      if (levels.isEmpty) return [];

      // Собираем все уроки из всех уровней по порядку
      final allLessons = <LessonModel>[];
      for (final level in levels) {
        allLessons.addAll(level.lessons);
      }
      if (allLessons.isEmpty) return [];

      return allLessons.asMap().entries.map((entry) {
        final i = entry.key;
        final lesson = entry.value;
        // Первый урок всегда разблокирован
        final isFirst = i == 0;
        return _MapLesson(
          backendId: lesson.id,
          fallbackIndex: i + 1,
          title: lesson.title,
          subtitleKk: lesson.title,
          description: '${lesson.xpReward} XP',
          unlocked: isFirst || lesson.unlocked,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_MapLesson>> _buildFallback() async {
    final done = await AppStorage.getCompletedLessons();
    return _kFallback.asMap().entries.map((entry) {
      final i = entry.key;
      final node = entry.value;
      final prevDone = i == 0 || done.contains(_kFallback[i - 1].lessonIndex);
      return _MapLesson(
        backendId: null,
        fallbackIndex: node.lessonIndex,
        title: node.title,
        subtitleKk: node.subtitleKk,
        description: node.description,
        unlocked: prevDone,
      );
    }).toList();
  }

  // ── Сегменты пути ─────────────────────────────────────────────────────────

  List<_SegmentKind> _segmentKinds() {
    final kinds = <_SegmentKind>[];
    for (var s = 0; s < _lessons.length - 1; s++) {
      final curr = _lessons[s];
      final next = _lessons[s + 1];
      if (!curr.unlocked) {
        kinds.add(_SegmentKind.locked);
      } else if (next.unlocked) {
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

    if (lesson.isBackend) {
      // Реальный урок с бэкенда
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseScreen(
            lessonId: lesson.backendId!,
            lessonTitle: lesson.title,
          ),
        ),
      );
    } else {
      // Оффлайн-фоллбэк
      final node = _kFallback.firstWhere(
        (n) => n.lessonIndex == lesson.fallbackIndex,
        orElse: () => _kFallback.first,
      );
      await LessonFlowScreen.open(context, node);
    }

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
    final completed = false; // серверная разблокировка определяется через unlocked следующего

    final borderColor = locked
        ? AppTheme.border
        : const Color(0xFFC9E85C);
    final borderW = locked ? 2.0 : 3.0;

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
              color: Colors.white,
              border: Border.all(color: borderColor, width: borderW),
              boxShadow: [
                if (!locked)
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 0,
                    color: const Color(0xFFC9E85C).withOpacity(0.4),
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
                  ? Icon(
                      Icons.lock_outline,
                      color: AppTheme.primary.withOpacity(0.65),
                      size: 26,
                    )
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
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF8FAF3A),
                          size: 22,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
