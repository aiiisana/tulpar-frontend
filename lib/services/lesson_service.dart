import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

// ── Exercise models ───────────────────────────────────────────────────────────

enum ExerciseType {
  VOCABULARY,
  SENTENCE_BUILDER,
  LISTENING,
  VIDEO_CONTEXT,
  IMAGE_CONTEXT,
  AI_GENERATED,
}

class ExerciseModel {
  final String id;
  final ExerciseType type;
  final String? difficultyLevel;
  final String? question;
  final String? explanation;

  // Vocabulary / listening / image
  final String? word;
  final String? translation;
  final String? audioUrl;
  final String? transcript;
  final String? imageUrl;
  final List<String> options;

  // Sentence builder
  final List<String> shuffledWords;

  ExerciseModel({
    required this.id,
    required this.type,
    this.difficultyLevel,
    this.question,
    this.explanation,
    this.word,
    this.translation,
    this.audioUrl,
    this.transcript,
    this.imageUrl,
    this.options = const [],
    this.shuffledWords = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> j) {
    return ExerciseModel(
      id:              j['id'] as String,
      type:            _parseType(j['type'] as String? ?? ''),
      difficultyLevel: j['difficultyLevel'] as String?,
      question:        j['question'] as String?,
      explanation:     j['explanation'] as String?,
      word:            j['word'] as String?,
      translation:     j['translation'] as String?,
      audioUrl:        j['audioUrl'] as String?,
      transcript:      j['transcript'] as String?,
      imageUrl:        j['imageUrl'] as String?,
      options:         List<String>.from(j['options'] as List<dynamic>? ?? []),
      shuffledWords:   List<String>.from(
                         j['shuffledWords'] as List<dynamic>? ?? []),
    );
  }

  static ExerciseType _parseType(String v) => switch (v.toUpperCase()) {
        'VOCABULARY'      => ExerciseType.VOCABULARY,
        'SENTENCE_BUILDER'=> ExerciseType.SENTENCE_BUILDER,
        'LISTENING'       => ExerciseType.LISTENING,
        'VIDEO_CONTEXT'   => ExerciseType.VIDEO_CONTEXT,
        'IMAGE_CONTEXT'   => ExerciseType.IMAGE_CONTEXT,
        _                 => ExerciseType.AI_GENERATED,
      };
}

// ── Lesson models ─────────────────────────────────────────────────────────────

class LessonModel {
  final String id;
  final String title;
  final int orderIndex;
  final int xpReward;
  final bool unlocked;
  final List<ExerciseModel> exercises;

  LessonModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
    required this.unlocked,
    this.exercises = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> j) {
    final rawExercises = j['exercises'] as List<dynamic>? ?? [];
    return LessonModel(
      id:         j['id'] as String,
      title:      j['title'] as String,
      orderIndex: (j['orderIndex'] as num?)?.toInt() ?? 0,
      xpReward:   (j['xpReward'] as num?)?.toInt() ?? 0,
      unlocked:   j['unlocked'] as bool? ?? false,
      exercises:  rawExercises
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Course level model ────────────────────────────────────────────────────────

class CourseLevelModel {
  final String id;
  final String title;
  final int orderIndex;
  final List<LessonModel> lessons;

  CourseLevelModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });

  factory CourseLevelModel.fromJson(Map<String, dynamic> j) {
    final rawLessons = j['lessons'] as List<dynamic>? ?? [];
    return CourseLevelModel(
      id:         j['id'] as String,
      title:      j['title'] as String,
      orderIndex: (j['orderIndex'] as num?)?.toInt() ?? 0,
      lessons:    rawLessons
          .map((l) => LessonModel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Course model ──────────────────────────────────────────────────────────────

class CourseModel {
  final String id;
  final String title;
  final String? description;
  final int orderIndex;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id:          j['id'] as String,
        title:       j['title'] as String,
        description: j['description'] as String?,
        orderIndex:  (j['orderIndex'] as num?)?.toInt() ?? 0,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class LessonService {
  static final _api = ApiClient();

  /// GET /courses — список курсов (обычно один курс «Казахский»)
  static Future<List<CourseModel>> getCourses() async {
    try {
      final res = await _api.get('/courses');
      final raw = res.data as List<dynamic>;
      return raw
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LessonService] getCourses failed: $e');
      return [];
    }
  }

  /// GET /courses/{courseId}/levels — уровни с уроками и статусом разблокировки
  static Future<List<CourseLevelModel>> getCourseLevels(String courseId) async {
    try {
      final res = await _api.get('/courses/$courseId/levels');
      final raw = res.data as List<dynamic>;
      return raw
          .map((e) => CourseLevelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LessonService] getCourseLevels failed: $e');
      return [];
    }
  }

  /// GET /lessons/{lessonId} — детальный урок с упражнениями
  static Future<LessonModel?> getLessonDetail(String lessonId) async {
    try {
      final res = await _api.get('/lessons/$lessonId');
      return LessonModel.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[LessonService] getLessonDetail failed: $e');
      return null;
    }
  }
}
