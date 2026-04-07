import '../app/api_client.dart';

// ── Модели ───────────────────────────────────────────────────────────────────

class StatsModel {
  final int currentStreak;
  final int longestStreak;
  final int totalXp;

  StatsModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
  });

  factory StatsModel.fromJson(Map<String, dynamic> j) => StatsModel(
        currentStreak: (j['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (j['longestStreak'] as num?)?.toInt() ?? 0,
        totalXp:       (j['totalXp']       as num?)?.toInt() ?? 0,
      );

  /// Фоллбэк при ошибке API
  factory StatsModel.empty() =>
      StatsModel(currentStreak: 0, longestStreak: 0, totalXp: 0);
}

class CalendarDay {
  final DateTime date;
  final bool completed;

  CalendarDay({required this.date, required this.completed});

  factory CalendarDay.fromJson(Map<String, dynamic> j) => CalendarDay(
        // бэкенд отдаёт LocalDate в формате "2026-04-06"
        date:      DateTime.parse(j['date'] as String),
        completed: (j['completed'] as bool?) ?? false,
      );

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Русское сокращение дня недели: 1=ПН … 7=ВС
  String get dayNameRu => const [
        '', // weekday начинается с 1
        'ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'
      ][date.weekday];

  String get dayNumber => '${date.day}';
}

// ── Загрузчик данных ─────────────────────────────────────────────────────────

class HomeData {
  final StatsModel stats;
  final List<CalendarDay> calendar;

  HomeData({required this.stats, required this.calendar});
}

class StatsService {
  static final _api = ApiClient();

  /// Загружает стрик + XP и недельный календарь одним вызовом.
  /// При ошибке возвращает пустые данные — UI не упадёт.
  static Future<HomeData> loadHomeData() async {
    StatsModel stats = StatsModel.empty();
    List<CalendarDay> calendar = [];

    try {
      final statsRes = await _api.get('/stats');
      stats = StatsModel.fromJson(statsRes.data as Map<String, dynamic>);
    } catch (_) {}

    try {
      final calRes = await _api.get('/stats/calendar');
      final raw = calRes.data as List<dynamic>;
      calendar = raw
          .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    return HomeData(stats: stats, calendar: calendar);
  }
}
