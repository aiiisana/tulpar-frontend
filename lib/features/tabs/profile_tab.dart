import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/app_strings.dart';
import '../../app/content_assets.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../services/profile_service.dart';
import '../../services/progress_service.dart';
import '../../services/stats_service.dart';
import '../settings/settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ── Display data ─────────────────────────────────────────────────────────────
  String displayName = '...';
  String levelLabel = 'Начинающий';
  int goalMin = 15;
  String uiLang = 'ru';
  int streakDays = 0;
  int completedLessons = 0;
  int totalXp = 0;
  // Progress summary from backend
  int totalExercisesCompleted = 0;
  int totalExercisesFailed = 0;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    await AppStorage.recordStreakVisitIfNeeded();

    final lang = await AppStorage.getUiLang();
    final placeholder = lang == 'en' ? 'User' : 'Пользователь';
    final done = await AppStorage.getCompletedLessons();

    // Fetch real profile from backend
    ProfileModel? profile;
    try {
      profile = await ProfileService.getProfile();
    } catch (_) {}

    // Fetch stats (streak, XP)
    StatsModel stats = StatsModel.empty();
    try {
      final homeData = await StatsService.loadHomeData();
      stats = homeData.stats;
    } catch (_) {}

    // Fetch progress summary (completed / failed exercises)
    ProgressSummary summary = ProgressSummary.empty();
    try {
      summary = await ProgressService.getSummary();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      uiLang = lang;
      completedLessons = done.length;
      totalExercisesCompleted = summary.totalCompleted;
      totalExercisesFailed    = summary.totalFailed;
      _loadingProfile = false;

      if (profile != null) {
        final raw = profile.username ?? '';
        displayName = raw.trim().isEmpty ? placeholder : raw.trim();
        levelLabel = profile.levelRu;
        goalMin = profile.goalMinutes;
        streakDays = profile.currentStreak > 0
            ? profile.currentStreak
            : stats.currentStreak;
        totalXp = profile.totalXp > 0 ? profile.totalXp : stats.totalXp;
      } else {
        // Fallback to local storage
        streakDays = stats.currentStreak;
        totalXp = stats.totalXp;
      }
    });

    // If backend didn't return a name, fall back to local storage
    if (profile == null || (profile.username ?? '').trim().isEmpty) {
      final f = await AppStorage.getFirstName();
      final l = await AppStorage.getLastName();
      final gMin = await AppStorage.getGoalMinutes();
      if (!mounted) return;
      setState(() {
        displayName = _buildDisplayName(f, l, placeholder);
        goalMin = gMin ?? 15;
      });
    }
  }

  String _buildDisplayName(String? first, String? last, String placeholder) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    if (f.isEmpty) return placeholder;
    if (l.isEmpty) return f;
    return '$f ${l.substring(0, 1).toUpperCase()}.';
  }

  // ── Edit name ────────────────────────────────────────────────────────────────

  Future<void> _editName() async {
    final scope = UiLocaleScope.of(context);
    final s = AppStr.fromContext(scope.locale);

    final isScopePlaceholder = displayName == s.userPlaceholder;
    final controllerFirst =
        TextEditingController(text: isScopePlaceholder ? '' : displayName);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.editNameTitle),
        content: TextField(
          decoration:
              InputDecoration(labelText: s.firstName),
          controller: controllerFirst,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.save)),
        ],
      ),
    );

    if (saved != true) return;

    final newName = controllerFirst.text.trim();
    if (newName.isEmpty) return;

    // Update on backend
    try {
      final updated = await ProfileService.updateUsername(newName);
      if (updated != null && mounted) {
        setState(() => displayName = updated.username ?? newName);
      }
    } catch (_) {}

    // Also save locally as fallback
    await AppStorage.saveProfile(firstName: newName, lastName: '');
    if (mounted) await _load();
  }

  // ── Change daily goal ─────────────────────────────────────────────────────────

  Future<void> _changeGoal() async {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));
    final options = [15, 30, 45, 60, 90, 120];

    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(s.pickDailyGoalTitle),
              subtitle: Text(s.pickDailyGoalSubtitle),
            ),
            for (final m in options)
              ListTile(
                title: Text('$m ${s.en ? 'min' : 'минут'}'),
                trailing:
                    m == goalMin ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );

    if (chosen == null) return;

    await AppStorage.setGoalMinutes(chosen);
    // Also sync to backend
    try {
      await ProfileService.updateDailyGoal(chosen);
    } catch (_) {}

    if (mounted) await _load();
  }

  // ── Change UI language ────────────────────────────────────────────────────────

  Future<void> _changeLang() async {
    final scope = UiLocaleScope.of(context);
    final s = AppStr.fromContext(scope.locale);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.langSheetTitle),
              subtitle: Text(s.langSheetSubtitle),
            ),
            ListTile(
              title: Text(s.russian),
              trailing:
                  uiLang == 'ru' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'ru'),
            ),
            ListTile(
              title: Text(s.english),
              trailing:
                  uiLang == 'en' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'en'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (chosen == null) return;

    await scope.applyLocale(chosen);
    if (mounted) await _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));
    final langText = uiLang == 'ru' ? s.russian : s.english;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    s.profileTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
                  // Reload profile after returning from settings
                  if (mounted) await _load();
                },
                icon: const Icon(Icons.settings,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Avatar + name block ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 10,
                          offset: Offset(0, 6),
                          color: Color(0x22000000))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                      child:
                          ContentAssets.profileAvatarWidget(size: 72)),
                ),
                const SizedBox(height: 10),
                _loadingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(levelLabel,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _editName,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                  ),
                  child: Text(s.edit,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Progress block ──────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(s.progress),
          ),
          const SizedBox(height: 8),
          _InfoCard(
            items: [
              _InfoRow(
                  icon: Icons.local_fire_department_outlined,
                  text: s.streakShort(streakDays)),
              _InfoRow(
                  icon: Icons.check_circle_outline,
                  text: s.lessonsDoneLine(completedLessons)),
              _InfoRow(
                  icon: Icons.star_outline,
                  text: '$totalXp XP'),
              if (totalExercisesCompleted > 0)
                _InfoRow(
                    icon: Icons.task_alt,
                    text: 'Упражнений выполнено: $totalExercisesCompleted'),
              if (totalExercisesFailed > 0)
                _InfoRow(
                    icon: Icons.cancel_outlined,
                    text: 'Ошибок: $totalExercisesFailed'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Achievements block ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(s.achievements),
          ),
          const SizedBox(height: 8),
          _InfoCard(
            items: [
              _InfoRow(
                  icon: Icons.emoji_events_outlined,
                  text: s.streakShort(streakDays)),
              _InfoRow(
                  icon: Icons.workspace_premium_outlined,
                  text: s.firstLessonAchievement),
            ],
          ),

          const SizedBox(height: 14),

          // ── Settings block ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.chipFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _ProfileSettingsTile(
                  title: s.dailyGoal,
                  value: s.minutesValue(goalMin),
                  onTap: _changeGoal,
                ),
                const Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: AppTheme.border),
                _ProfileSettingsTile(
                  title: s.appLanguage,
                  value: langText,
                  onTap: _changeLang,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w800));
  }
}

class _InfoRow {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.chipFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(items[i].icon,
                    size: 20, color: AppTheme.textPrimary),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(items[i].text,
                        style: const TextStyle(
                            fontSize: 13, height: 1.25))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSettingsTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ProfileSettingsTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
