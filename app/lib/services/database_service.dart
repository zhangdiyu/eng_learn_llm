import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/evaluation.dart';

class DatabaseService {
  static const _attemptsKey = 'db_attempts';
  static const _reviewQueueKey = 'db_review_queue';
  static const _achievementsKey = 'db_achievements';
  static const _attemptCounterKey = 'db_attempt_counter';
  static const _reviewCounterKey = 'db_review_counter';
  static SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _instance;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await _instance;
    await prefs.setString(key, jsonEncode(value));
  }

  Future<int> _nextId(String key) async {
    final prefs = await _instance;
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  Future<int> saveAttempt({
    required String questionId,
    required String questionJson,
    required String userAnswer,
  }) async {
    final attempts = await _readList(_attemptsKey);
    final id = await _nextId(_attemptCounterKey);
    attempts.add({
      'id': id,
      'question_id': questionId,
      'question_json': questionJson,
      'user_answer': userAnswer,
      'evaluation_json': null,
      'score': null,
      'verdict': null,
      'created_at': DateTime.now().toIso8601String(),
      'reviewed': 0,
    });
    await _writeList(_attemptsKey, attempts);
    return id;
  }

  Future<void> updateAttemptEvaluation(
    int id,
    AnswerEvaluation evaluation,
  ) async {
    final attempts = await _readList(_attemptsKey);
    final index = attempts.indexWhere((item) => item['id'] == id);
    if (index == -1) return;

    attempts[index] = {
      ...attempts[index],
      'evaluation_json': jsonEncode(evaluation.toJson()),
      'score': evaluation.score,
      'verdict': evaluation.verdict,
    };
    await _writeList(_attemptsKey, attempts);
  }

  Future<List<Map<String, dynamic>>> getAttemptHistory({int limit = 50}) async {
    final attempts = await _readList(_attemptsKey);
    attempts.sort(
      (a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String),
    );
    return attempts.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getReviewQueue() async {
    final reviewQueue = await _readList(_reviewQueueKey);
    final now = DateTime.now().toIso8601String();
    final due = reviewQueue
        .where((item) =>
            (item['mastered'] as int? ?? 0) == 0 &&
            (item['next_review'] as String).compareTo(now) <= 0)
        .toList();
    due.sort(
      (a, b) =>
          (a['next_review'] as String).compareTo(b['next_review'] as String),
    );
    return due;
  }

  Future<void> addToReviewQueue({
    required int attemptId,
    required String questionId,
    required String errorType,
  }) async {
    final reviewQueue = await _readList(_reviewQueueKey);
    final id = await _nextId(_reviewCounterKey);
    final nextReview = DateTime.now()
        .add(const Duration(hours: 4))
        .toIso8601String();
    reviewQueue.add({
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'error_type': errorType,
      'next_review': nextReview,
      'review_count': 0,
      'mastered': 0,
    });
    await _writeList(_reviewQueueKey, reviewQueue);
  }

  Future<void> updateReviewItem(int id, {bool mastered = false}) async {
    final reviewQueue = await _readList(_reviewQueueKey);
    final index = reviewQueue.indexWhere((item) => item['id'] == id);
    if (index == -1) return;

    if (mastered) {
      reviewQueue[index] = {
        ...reviewQueue[index],
        'mastered': 1,
      };
    } else {
      final count = (reviewQueue[index]['review_count'] as int? ?? 0) + 1;
      final intervals = [4, 12, 24, 72, 168, 336];
      final hours = intervals[count.clamp(0, intervals.length - 1)];
      final nextReview =
          DateTime.now().add(Duration(hours: hours)).toIso8601String();
      reviewQueue[index] = {
        ...reviewQueue[index],
        'review_count': count,
        'next_review': nextReview,
      };
    }

    await _writeList(_reviewQueueKey, reviewQueue);
  }

  Future<void> unlockAchievement(String key) async {
    final achievements = await _readList(_achievementsKey);
    final exists = achievements.any((item) => item['key'] == key);
    if (exists) return;

    achievements.add({
      'key': key,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
    await _writeList(_achievementsKey, achievements);
  }

  Future<List<String>> getAchievements() async {
    final achievements = await _readList(_achievementsKey);
    return achievements.map((item) => item['key'] as String).toList();
  }
}
