import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning.dart';
import '../models/opening_experience.dart';

class StorageService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  static const _apiKeyKey = 'deepseek_api_key';
  static const _prefsLevel = 'proficiency_level';
  static const _prefsTopics = 'learning_topics';
  static const _prefsSound = 'sound_enabled';
  static const _prefsVibration = 'vibration_enabled';
  static const _prefsDailyGoal = 'daily_goal';
  static const _prefsXp = 'total_xp';
  static const _prefsStreak = 'current_streak';
  static const _prefsLongestStreak = 'longest_streak';
  static const _prefsAnswered = 'questions_answered';
  static const _prefsTodayCount = 'today_count';
  static const _prefsLastDate = 'last_active_date';
  static const _openingHistoryKey = 'opening_history';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // API Key — dual-store for web compatibility
  Future<void> saveApiKey(String key) async {
    await _secure.write(key: _apiKeyKey, value: key);
    // Fallback: also save to SharedPreferences (web uses IndexedDB through secure_storage_web)
    await _prefs?.setString(_apiKeyKey, key);
  }

  Future<String?> getApiKey() async {
    final key = await _secure.read(key: _apiKeyKey);
    if (key != null && key.isNotEmpty) return key;
    // Fallback: read from SharedPreferences
    return _prefs?.getString(_apiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _secure.delete(key: _apiKeyKey);
    await _prefs?.remove(_apiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  // Learning Preferences
  Future<void> savePreferences(LearningPreferences prefs) async {
    await _prefs?.setString(_prefsLevel, prefs.level.name);
    await _prefs?.setStringList(
        _prefsTopics, prefs.topics.map((t) => t.name).toList());
    await _prefs?.setBool(_prefsSound, prefs.soundEnabled);
    await _prefs?.setBool(_prefsVibration, prefs.vibrationEnabled);
    await _prefs?.setInt(_prefsDailyGoal, prefs.dailyGoal);
  }

  LearningPreferences loadPreferences() {
    final levelStr = _prefs?.getString(_prefsLevel) ?? 'beginner';
    final topicsStr = _prefs?.getStringList(_prefsTopics) ?? ['daily'];
    return LearningPreferences(
      level: ProficiencyLevel.values.firstWhere(
        (e) => e.name == levelStr,
        orElse: () => ProficiencyLevel.beginner,
      ),
      topics: topicsStr
          .map((t) => LearningTopic.values.firstWhere(
                (e) => e.name == t,
                orElse: () => LearningTopic.daily,
              ))
          .toSet(),
      soundEnabled: _prefs?.getBool(_prefsSound) ?? true,
      vibrationEnabled: _prefs?.getBool(_prefsVibration) ?? true,
      dailyGoal: _prefs?.getInt(_prefsDailyGoal) ?? 20,
    );
  }

  // User Stats
  UserStats loadStats() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _prefs?.getString(_prefsLastDate) ?? '';
    final todayCount = lastDate == today ? (_prefs?.getInt(_prefsTodayCount) ?? 0) : 0;

    return UserStats(
      totalXp: _prefs?.getInt(_prefsXp) ?? 0,
      currentStreak: _prefs?.getInt(_prefsStreak) ?? 0,
      longestStreak: _prefs?.getInt(_prefsLongestStreak) ?? 0,
      questionsAnswered: _prefs?.getInt(_prefsAnswered) ?? 0,
      todayCount: todayCount,
    );
  }

  Future<void> saveStats(UserStats stats) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs?.setInt(_prefsXp, stats.totalXp);
    await _prefs?.setInt(_prefsStreak, stats.currentStreak);
    await _prefs?.setInt(_prefsLongestStreak, stats.longestStreak);
    await _prefs?.setInt(_prefsAnswered, stats.questionsAnswered);
    await _prefs?.setInt(_prefsTodayCount, stats.todayCount);
    await _prefs?.setString(_prefsLastDate, today);
  }

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs?.clear();
  }

  // Question/Answer cache
  Future<void> cacheQuestion(String questionId, String json) async {
    await _prefs?.setString('q_$questionId', json);
  }

  String? getCachedQuestion(String questionId) {
    return _prefs?.getString('q_$questionId');
  }

  List<String> getCachedQuestionIds() {
    final keys = _prefs?.getKeys() ?? {};
    return keys.where((k) => k.startsWith('q_')).map((k) => k.substring(2)).toList();
  }

  Future<void> cacheEvaluation(int attemptId, String json) async {
    await _prefs?.setString('eval_$attemptId', json);
  }

  String? getCachedEvaluation(int attemptId) {
    return _prefs?.getString('eval_$attemptId');
  }

  List<Map<String, dynamic>> getOpeningHistory() {
    final raw = _prefs?.getString(_openingHistoryKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> recordOpeningExposure(OpeningCardData card) async {
    final history = getOpeningHistory();
    history.insert(0, {
      ...card.toJson(),
      'shownAt': DateTime.now().toIso8601String(),
    });
    await _prefs?.setString(
      _openingHistoryKey,
      jsonEncode(history.take(20).toList()),
    );
  }
}
