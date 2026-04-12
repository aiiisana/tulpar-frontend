import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../services/session_time_service.dart';
import '../tabs/home_tab.dart';
import '../tabs/learning_tab.dart';
import '../tabs/tasks_tab.dart';
import '../tabs/profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int index = 0;

  late final List<Widget> pages = [
    HomeTab(onProfileTap: () => setState(() => index = 3)),
    const LearningTab(),
    const TasksTab(),
    const ProfileTab(),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start counting time as soon as the home shell is mounted (user is active).
    SessionTimeService.startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Flush any remaining time when the widget is destroyed.
    SessionTimeService.flushSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground — start a new segment.
        SessionTimeService.startSession();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background / closing — flush accumulated time.
        SessionTimeService.flushSession();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.75),
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: s.tabHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book_rounded),
            label: s.tabLearn,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_fire_department_outlined),
            activeIcon: const Icon(Icons.local_fire_department_rounded),
            label: s.tabTask,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person_rounded),
            label: s.tabProfile,
          ),
        ],
      ),
    );
  }
}
