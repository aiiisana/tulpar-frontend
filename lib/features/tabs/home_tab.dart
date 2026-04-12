import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/home_level_map.dart';
import '../../widgets/primary_button.dart';
import '../../app/app_storage.dart';
import '../../app/app_strings.dart';
import '../../app/ui_locale.dart';
import '../../services/profile_service.dart';
import '../../services/stats_service.dart';

// ── Home header model ─────────────────────────────────────────────────────────

class _HomeHeaderData {
  final String name;
  final int streakDays;
  final List<CalendarDay> calendar;
  final String? imageUrl;

  const _HomeHeaderData({
    required this.name,
    required this.streakDays,
    required this.calendar,
    this.imageUrl,
  });
}

class HomeTab extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeTab({super.key, this.onProfileTap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final GlobalKey<HomeLevelMapState> _mapKey = GlobalKey<HomeLevelMapState>();
  late Future<_HomeHeaderData> _headerFuture;
  String? _lastUiLang;

  @override
  void initState() {
    super.initState();
    _headerFuture = _loadHeader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = UiLocaleScope.langOf(context);
    if (_lastUiLang == null) {
      _lastUiLang = lang;
      return;
    }
    if (_lastUiLang != lang) {
      _lastUiLang = lang;
      setState(() {
        _headerFuture = _loadHeader();
      });
    }
  }

  Future<_HomeHeaderData> _loadHeader() async {
    // Also record a local visit for offline streak tracking
    await AppStorage.recordStreakVisitIfNeeded();

    final lang = await AppStorage.getUiLang();
    final placeholder = lang == 'en' ? 'User' : 'Пользователь';

    // Fetch real data from backend (both profile + stats)
    String name = placeholder;
    int streak = 0;
    List<CalendarDay> calendar = [];
    String? imageUrl;

    ProfileModel? profile;
    try {
      profile = await ProfileService.getProfile();
      if (profile != null) {
        final raw = profile.username ?? '';
        final trimmed = raw.trim();
        name = trimmed.isEmpty ? placeholder : trimmed.split(' ').first;
        streak = profile.currentStreak;

        imageUrl = profile.avatarUrl;
      }
    } catch (_) {
      streak = await AppStorage.getStreakDays();
    }

    // If name is still placeholder, fall back to local storage
    if (name == placeholder) {
      final first = await AppStorage.getFirstName();
      final last = await AppStorage.getLastName();
      final f = (first ?? '').trim();
      if (f.isNotEmpty) name = f;
    }

    try {
      final homeData = await StatsService.loadHomeData();
      // Prefer backend streak if it's set
      if (homeData.stats.currentStreak > 0) {
        streak = homeData.stats.currentStreak;
      }
      calendar = homeData.calendar;
    } catch (_) {}

    return _HomeHeaderData(name: name, streakDays: streak, calendar: calendar, imageUrl: imageUrl);
  }

  Future<void> _startLesson() async {
    // Открываем первый доступный незавершённый урок напрямую в ExerciseScreen
    await HomeLevelMap.openRecommendedLesson(context);
    await _mapKey.currentState?.reloadProgress();
    if (mounted) {
      setState(() {
        _headerFuture = _loadHeader();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    return FutureBuilder<_HomeHeaderData>(
      future: _headerFuture,
      builder: (context, snap) {
        final name = snap.data?.name ?? '...';
        final streak = snap.data?.streakDays ?? 0;
        final calendar = snap.data?.calendar;
        final imageUrl = snap.data?.imageUrl;
        // If we have backend calendar data, use it; otherwise fall back to
        // a simple "week around today" display.
        final weekCells = _buildWeekCells(s.weekDayLabels, calendar);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Қайырлы таң, $name!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            offset: Offset(0, 6),
                            color: Color(0x22000000),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClipOval(
                          child: Image.network(
                            key: ValueKey(imageUrl), // обязательно
                            imageUrl ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Image.asset(
                                'assets/images/face1.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                s.dailyPractice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // Calendar row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekCells,
              ),

              const SizedBox(height: 10),
              Text(
                s.streakLine(streak),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 14),
              PrimaryButton(text: s.startLesson, onPressed: _startLesson),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: HomeLevelMap(key: _mapKey),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a list of 7 day cells for the week.
  /// If [calendar] is provided by the backend, uses its completed flags.
  /// Otherwise, falls back to a simple "past / today / future" heuristic.
  List<Widget> _buildWeekCells(
    List<String> dayLabels,
    List<CalendarDay>? calendar,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );

    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final date = d.day;
      final label = dayLabels[i];

      final isFuture = d.isAfter(today);
      final isToday = d == today;

      // Check backend calendar for completed status
      bool completed = false;
      if (calendar != null && calendar.isNotEmpty) {
        completed = calendar.any(
          (c) =>
              c.date.year == d.year &&
              c.date.month == d.month &&
              c.date.day == d.day &&
              c.completed,
        );
      } else if (!isFuture && !isToday) {
        // No backend data — treat all past days as "past" (not completed)
        completed = false;
      }

      if (isFuture) {
        return SizedBox(
          width: 38,
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$date',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isToday
              ? Colors.white
              : completed
              ? AppTheme.primary.withOpacity(0.12)
              : AppTheme.calendarDayBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? AppTheme.primary
                : completed
                ? AppTheme.primary.withOpacity(0.5)
                : AppTheme.border,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: completed && !isToday
                    ? AppTheme.primary
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            completed && !isToday
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppTheme.primary,
                  )
                : Text('$date', style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
    });
  }
}
