import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/circle_back_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  // ── Tabs ──────────────────────────────────────────────────────────────────
  late final TabController _tabCtrl;

  // ── Toggle state (synced to backend via PUT /profile) ─────────────────────
  bool _lessons = true;
  bool _streak = true;
  bool _sounds = false;
  bool _savingToggles = false;

  // ── In-app notifications from backend ────────────────────────────────────
  List<NotificationModel> _notifications = [];
  bool _loadingNotifs = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadProfileToggles();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    setState(() => _loadingNotifs = true);
    final list = await NotificationService.getList(size: 50);
    if (!mounted) return;
    setState(() {
      _notifications = list;
      _loadingNotifs = false;
    });
  }

  Future<void> _loadProfileToggles() async {
    final profile = await ProfileService.getProfile();
    if (!mounted) return;
    if (profile != null) {
      setState(() => _lessons = profile.notificationsEnabled);
    }
  }

  // ── Mark notifications as read ────────────────────────────────────────────

  Future<void> _markRead(NotificationModel n) async {
    if (n.read) return;
    final updated = await NotificationService.markRead(n.id);
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) _notifications[idx] = updated;
      });
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.read).toList();
    for (final n in unread) {
      await NotificationService.markRead(n.id);
    }
    if (!mounted) return;
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(read: true)).toList();
    });
  }

  // ── Toggle: sync notificationsEnabled to backend ──────────────────────────

  Future<void> _toggleLessons(bool value) async {
    setState(() {
      _lessons = value;
      _savingToggles = true;
    });
    try {
      await ProfileService.updateNotificationsEnabled(value);
    } catch (_) {}
    if (mounted) setState(() => _savingToggles = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      s.notifTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(
                        'Прочитать все',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.primary),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabCtrl,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Входящие'),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Настройки'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _inboxTab(),
                  _settingsTab(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inbox: real notifications from backend ────────────────────────────────

  Widget _inboxTab() {
    if (_loadingNotifs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none,
                color: AppTheme.textSecondary, size: 56),
            const SizedBox(height: 14),
            const Text('Нет уведомлений',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text('Обновить'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = _notifications[i];
          return _NotificationTile(
            notification: n,
            onTap: () => _markRead(n),
          );
        },
      ),
    );
  }

  // ── Settings: toggles ─────────────────────────────────────────────────────

  Widget _settingsTab(AppStr s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        if (_savingToggles)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        _tile(s.notifLessonReminders, s.notifLessonRemindersSub,
            _lessons, _toggleLessons),
        _tile(s.notifStreak, s.notifStreakSub, _streak,
            (v) => setState(() => _streak = v)),
        _tile(s.notifSounds, s.notifSoundsSub, _sounds,
            (v) => setState(() => _sounds = v)),
      ],
    );
  }

  Widget _tile(
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.chipFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        value: value,
        activeTrackColor: AppTheme.primary.withOpacity(0.55),
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? AppTheme.primary.withOpacity(0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? AppTheme.primary.withOpacity(0.3)
                : AppTheme.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Container(
              margin: const EdgeInsets.only(top: 5, right: 10),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isUnread ? AppTheme.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
