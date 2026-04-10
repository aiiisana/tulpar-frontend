import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/lesson_service.dart';
import 'exercise_screen.dart';

/// Экран «Карта уроков» — показывает все уровни курса,
/// внутри каждого — уроки с кнопкой запуска.
class LessonMapScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const LessonMapScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<LessonMapScreen> createState() => _LessonMapScreenState();
}

class _LessonMapScreenState extends State<LessonMapScreen> {
  List<CourseLevelModel> _levels = [];
  bool _loading = true;
  bool _needsLevelSelection = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final levels = await LessonService.getCourseLevels(widget.courseId);
    if (!mounted) return;
    setState(() {
      _levels = levels;
      // Empty list means the user has not selected a difficulty level yet.
      _needsLevelSelection = levels.isEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.courseTitle),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _needsLevelSelection
              ? _noLevelState()
              : _levels.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    itemCount: _levels.length,
                    itemBuilder: (context, i) =>
                        _LevelSection(
                      level: _levels[i],
                      isLast: i == _levels.length - 1,
                    ),
                  ),
                ),
    );
  }

  Widget _noLevelState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Уровень не выбран',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Пройдите настройку уровня, чтобы видеть свои уроки',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined,
              size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('Уроки пока не добавлены',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Повторить',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Секция уровня ─────────────────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final CourseLevelModel level;
  final bool isLast;

  const _LevelSection({required this.level, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок уровня
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            level.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),

        // Уроки
        ...level.lessons.map(
          (lesson) => _LessonTile(lesson: lesson),
        ),

        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }
}

// ── Плитка урока ──────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final unlocked = lesson.unlocked;

    return GestureDetector(
      onTap: unlocked
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseScreen(
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                  ),
                ),
              )
          : () => _showLockedSnack(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                unlocked ? AppTheme.primary.withOpacity(0.25) : AppTheme.border,
          ),
          boxShadow: unlocked
              ? const [
                  BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      color: Color(0x18000000))
                ]
              : null,
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.chipFill
                    : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
                color: unlocked
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Название + XP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: unlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bolt,
                          size: 14,
                          color: unlocked
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${lesson.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          color: unlocked
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Стрелка / замок
            Icon(
              unlocked ? Icons.chevron_right : Icons.lock,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Сначала завершите предыдущие уроки'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
