import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_flashcard.dart';

class AppStorage {
  static const _kLoggedIn = 'logged_in';
  static const _kLevel = 'kazakh_level';
  static const _kGoal = 'daily_goal_minutes';
  static const _kEmail = 'auth_email';
  static const _kPassHash = 'auth_pass_hash';
  static const _kFirstNamePrefix = 'first_name';
  static const _kLastNamePrefix = 'last_name';
  static const _kUiLang = 'ui_lang';
  static const _kBioEnabled = 'bio_enabled';

  static Future<String> _savedWordsPrefsKey() async {
    final p = await SharedPreferences.getInstance();
    final email = (p.getString(_kEmail) ?? '').trim().toLowerCase();
    if (email.isNotEmpty) {
      final hash = sha256.convert(utf8.encode(email)).toString();
      return 'saved_words_$hash';
    }
    final ph = p.getString(_kPassHash);
    if (ph != null && ph.isNotEmpty) {
      final hash = sha256.convert(utf8.encode('local_ph|$ph')).toString();
      return 'saved_words_$hash';
    }
    return 'saved_words_local_anon';
  }

  static Future<List<SavedFlashcard>> getSavedWords() async {
    final key = await _savedWordsPrefsKey();
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedFlashcard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeSavedWords(List<SavedFlashcard> words) async {
    final key = await _savedWordsPrefsKey();
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(words.map((w) => w.toJson()).toList()));
  }

  static Future<bool> isFlashcardSaved(String id) async {
    final list = await getSavedWords();
    return list.any((w) => w.id == id);
  }

  static Future<void> saveFlashcard(SavedFlashcard word) async {
    final list = await getSavedWords();
    if (list.any((w) => w.id == word.id)) return;
    list.add(word);
    await _writeSavedWords(list);
  }

  static Future<void> removeSavedFlashcard(String id) async {
    final list = await getSavedWords();
    list.removeWhere((w) => w.id == id);
    await _writeSavedWords(list);
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, value);
  }

  static Future<void> saveCredentials({
    required String email,
    required String passwordHash,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmail, email);
    await p.setString(_kPassHash, passwordHash);
  }

  static Future<String?> getEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  static Future<String?> getPasswordHash() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPassHash);
  }

  static Future<String?> getLevel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLevel);
  }

  static Future<void> setLevel(String level) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLevel, level);
  }

  static Future<int?> getGoalMinutes() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kGoal);
  }

  static Future<void> setGoalMinutes(int minutes) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGoal, minutes);
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, false);
  }

  /// Returns a key suffix scoped to the current Firebase user (uid),
  /// so that names stored by User A are never visible to User B.
  static String _uidSuffix() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return '_$uid';
    return ''; // anonymous / not yet logged in — no suffix (safe fallback)
  }

  static Future<void> saveProfile({
    required String firstName,
    required String lastName,
  }) async {
    final p = await SharedPreferences.getInstance();
    final s = _uidSuffix();
    await p.setString('$_kFirstNamePrefix$s', firstName);
    await p.setString('$_kLastNamePrefix$s', lastName);
  }

  static Future<String?> getFirstName() async {
    final p = await SharedPreferences.getInstance();
    final s = _uidSuffix();
    return p.getString('$_kFirstNamePrefix$s');
  }

  static Future<String?> getLastName() async {
    final p = await SharedPreferences.getInstance();
    final s = _uidSuffix();
    return p.getString('$_kLastNamePrefix$s');
  }

  static Future<void> setUiLang(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUiLang, lang);
  }

  static Future<String> getUiLang() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUiLang) ?? 'ru';
  }

  static Future<bool> isBioEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kBioEnabled) ?? false;
  }

  static Future<void> setBioEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBioEnabled, value);
  }

  static Future<String> _accountPrefsPrefix() async {
    final p = await SharedPreferences.getInstance();
    final email = (p.getString(_kEmail) ?? '').trim().toLowerCase();
    if (email.isNotEmpty) {
      return 'acc_${sha256.convert(utf8.encode(email)).toString()}';
    }
    final ph = p.getString(_kPassHash);
    if (ph != null && ph.isNotEmpty) {
      return 'acc_${sha256.convert(utf8.encode('local_ph|$ph')).toString()}';
    }
    return 'acc_local_anon';
  }

  static String _ymd(DateTime d) {
    final l = d.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '${l.year}-$m-$day';
  }

  static Future<int> recordStreakVisitIfNeeded() async {
    final p = await SharedPreferences.getInstance();
    final prefix = await _accountPrefsPrefix();
    final lastKey = '${prefix}_streak_last';
    final streakKey = '${prefix}_streak_count';
    final today = _ymd(DateTime.now());
    final last = p.getString(lastKey);
    var streak = p.getInt(streakKey) ?? 0;

    if (last == today) {
      return streak > 0 ? streak : 1;
    }

    if (last == null || last.isEmpty) {
      streak = 1;
    } else {
      try {
        final lastDate = DateTime.parse(last);
        final t = DateTime.parse(today);
        final lastNorm = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final tNorm = DateTime(t.year, t.month, t.day);
        final diff = tNorm.difference(lastNorm).inDays;
        if (diff == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      } catch (_) {
        streak = 1;
      }
    }

    await p.setString(lastKey, today);
    await p.setInt(streakKey, streak);
    return streak;
  }

  static Future<int> getStreakDays() async {
    final p = await SharedPreferences.getInstance();
    final prefix = await _accountPrefsPrefix();
    final streakKey = '${prefix}_streak_count';
    final lastKey = '${prefix}_streak_last';
    final n = p.getInt(streakKey);
    if (n != null && n > 0) return n;
    final last = p.getString(lastKey);
    return last != null ? 1 : 0;
  }

  static Future<Set<int>> getCompletedLessons() async {
    final p = await SharedPreferences.getInstance();
    final prefix = await _accountPrefsPrefix();
    final raw = p.getString('${prefix}_lessons_done');
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markLessonCompleted(int lessonIndex) async {
    final set = await getCompletedLessons();
    set.add(lessonIndex);
    final sorted = set.toList()..sort();
    final p = await SharedPreferences.getInstance();
    final prefix = await _accountPrefsPrefix();
    await p.setString('${prefix}_lessons_done', jsonEncode(sorted));
  }

  static Future<bool> isLessonUnlocked(int lessonIndex) async {
    if (lessonIndex <= 1) return true;
    final c = await getCompletedLessons();
    return c.contains(lessonIndex - 1);
  }
}
