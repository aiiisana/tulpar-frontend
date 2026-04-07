import 'package:flutter/material.dart';
import '../app/app_storage.dart';
import '../app/theme.dart';
import '../features/lessons/lesson_flow_screen.dart';
import '../models/level_map_node.dart';

const double kLevelMapWidth = 420;
const double kLevelMapHeight = 560;

const double kMapCanvasPadding = 28;

const double kMapCanvasWidth = kLevelMapWidth + kMapCanvasPadding * 2;
const double kMapCanvasHeight = kLevelMapHeight + kMapCanvasPadding * 2;

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
          w = 7;
        case _SegmentKind.next:
          main = const Color(0xFFC9E85C);
          w = 11;
        case _SegmentKind.completed:
          main = AppTheme.primary;
          w = 10;
      }

      if (kind == _SegmentKind.next) {
        final glow = Paint()
          ..color = const Color(0xFFE8F5A0).withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, glow);
      }

      final line = Paint()
        ..color = main
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (kind == _SegmentKind.locked) {
        line.strokeWidth = 6;
      }

      canvas.drawPath(path, line);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.kinds != kinds;
  }
}

class HomeLevelMap extends StatefulWidget {
  const HomeLevelMap({super.key});

  static const lessons = <LevelMapNode>[
    LevelMapNode(
      lessonIndex: 1,
      title: 'Привет!',
      subtitleKk: 'Сәлем!',
      description:
          'Первые фразы приветствия и прощания, простые ответы. Потренируйтесь с аудио и карточками.',
      center: Offset(kLevelMapWidth * 0.52, 68),
    ),
    LevelMapNode(
      lessonIndex: 2,
      title: 'Знакомство',
      subtitleKk: 'Танысу',
      description: 'Как представиться, спросить имя и страну. Базовые вопросы «кім?», «қайдан?».',
      center: Offset(kLevelMapWidth * 0.22, 188),
    ),
    LevelMapNode(
      lessonIndex: 3,
      title: 'Семья',
      subtitleKk: 'Отбасы',
      description: 'Слова про семью: әке, ана, аға, сіңлі. Простые предложения о родственниках.',
      center: Offset(kLevelMapWidth * 0.72, 288),
    ),
    LevelMapNode(
      lessonIndex: 4,
      title: 'В городе',
      subtitleKk: 'Қалада',
      description: 'Дорога, транспорт, «қай жақта?» — ориентация и полезные выражения в городе.',
      center: Offset(kLevelMapWidth * 0.28, 392),
    ),
    LevelMapNode(
      lessonIndex: 5,
      title: 'Еда',
      subtitleKk: 'Тамақ',
      description: 'Названия блюд и напитков, «мен таңдаймын», вежливые фразы за столом.',
      center: Offset(kLevelMapWidth * 0.62, 500),
    ),
  ];

  static List<Offset> get centers => lessons.map((n) => n.center).toList();

  static Future<void> openRecommendedLesson(BuildContext context) async {
    final done = await AppStorage.getCompletedLessons();
    for (final n in lessons) {
      if (done.contains(n.lessonIndex)) continue;
      if (await AppStorage.isLessonUnlocked(n.lessonIndex)) {
        await openLessonByIndex(context, n.lessonIndex);
        return;
      }
    }
    await openLessonByIndex(context, lessons.last.lessonIndex);
  }

  static Future<void> openLessonByIndex(BuildContext context, int lessonIndex) async {
    if (!await AppStorage.isLessonUnlocked(lessonIndex)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала пройдите предыдущий урок')),
      );
      return;
    }
    for (final n in lessons) {
      if (n.lessonIndex == lessonIndex) {
        if (!context.mounted) return;
        await LessonFlowScreen.open(context, n);
        return;
      }
    }
  }

  @override
  State<HomeLevelMap> createState() => HomeLevelMapState();
}

class HomeLevelMapState extends State<HomeLevelMap> {
  Set<int> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reloadProgress();
  }

  Future<void> reloadProgress() async {
    final c = await AppStorage.getCompletedLessons();
    if (!mounted) return;
    setState(() {
      _completed = c;
      _loading = false;
    });
  }

  List<_SegmentKind> _segmentKinds() {
    final kinds = <_SegmentKind>[];
    for (var s = 0; s < HomeLevelMap.centers.length - 1; s++) {
      final fromLesson = s + 1;
      final toLesson = s + 2;
      final doneFrom = _completed.contains(fromLesson);
      final doneTo = _completed.contains(toLesson);
      if (doneTo) {
        kinds.add(_SegmentKind.completed);
      } else if (doneFrom) {
        kinds.add(_SegmentKind.next);
      } else {
        kinds.add(_SegmentKind.locked);
      }
    }
    return kinds;
  }

  Future<void> _onNodeTap(LevelMapNode node) async {
    if (!await AppStorage.isLessonUnlocked(node.lessonIndex)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала пройдите предыдущий урок')),
      );
      return;
    }
    if (!mounted) return;
    await LessonFlowScreen.open(context, node);
    await reloadProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 380,
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    const nodeSize = 72.0;
    const half = nodeSize / 2;
    final kinds = _segmentKinds();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: 380,
        child: InteractiveViewer(
          alignment: Alignment.center,
          minScale: 0.85,
          maxScale: 1.55,
          boundaryMargin: const EdgeInsets.all(12),
          constrained: false,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: kMapCanvasWidth,
            height: kMapCanvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 0,
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
                Positioned(
                  left: kMapCanvasPadding,
                  top: kMapCanvasPadding,
                  width: kLevelMapWidth,
                  height: kLevelMapHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: const Size(kLevelMapWidth, kLevelMapHeight),
                        painter: _LevelPathPainter(
                          points: HomeLevelMap.centers,
                          kinds: kinds,
                        ),
                      ),
                      for (final node in HomeLevelMap.lessons)
                        Positioned(
                          left: node.center.dx - half,
                          top: node.center.dy - half,
                          width: nodeSize,
                          height: nodeSize,
                          child: _LevelNodeBubble(
                            node: node,
                            completed: _completed.contains(node.lessonIndex),
                            unlocked: _completed.contains(node.lessonIndex - 1) || node.lessonIndex == 1,
                            onTap: () => _onNodeTap(node),
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

class _LevelNodeBubble extends StatelessWidget {
  final LevelMapNode node;
  final bool completed;
  final bool unlocked;
  final VoidCallback onTap;

  const _LevelNodeBubble({
    required this.node,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    final borderColor = completed
        ? AppTheme.primary
        : unlocked
            ? const Color(0xFFC9E85C)
            : AppTheme.border;
    final borderW = completed ? 3.5 : (unlocked ? 3.0 : 2.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? AppTheme.chipFill : Colors.white,
              border: Border.all(color: borderColor, width: borderW),
              boxShadow: [
                if (unlocked && !completed)
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 0,
                    color: const Color(0xFFC9E85C).withOpacity(0.45),
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
                  ? Icon(Icons.lock_outline, color: AppTheme.primary.withOpacity(0.65), size: 26)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${node.lessonIndex}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Icon(
                          completed ? Icons.check_circle_rounded : Icons.star_rounded,
                          color: completed ? AppTheme.primary : const Color(0xFF8FAF3A),
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
