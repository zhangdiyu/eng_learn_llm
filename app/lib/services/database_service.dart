import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/evaluation.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daily_english_quest.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        question_json TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        evaluation_json TEXT,
        score INTEGER,
        verdict TEXT,
        created_at TEXT NOT NULL,
        reviewed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE review_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        question_id TEXT NOT NULL,
        error_type TEXT NOT NULL,
        next_review TEXT NOT NULL,
        review_count INTEGER DEFAULT 0,
        mastered INTEGER DEFAULT 0,
        FOREIGN KEY (attempt_id) REFERENCES attempts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        unlocked_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> saveAttempt({
    required String questionId,
    required String questionJson,
    required String userAnswer,
  }) async {
    final db = await database;
    return db.insert('attempts', {
      'question_id': questionId,
      'question_json': questionJson,
      'user_answer': userAnswer,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateAttemptEvaluation(int id, AnswerEvaluation evaluation) async {
    final db = await database;
    await db.update('attempts', {
      'evaluation_json': jsonEncode(evaluation.toJson()),
      'score': evaluation.score,
      'verdict': evaluation.verdict,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAttemptHistory({int limit = 50}) async {
    final db = await database;
    return db.query('attempts',
        orderBy: 'created_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getReviewQueue() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.query('review_queue',
        where: 'next_review <= ? AND mastered = 0',
        whereArgs: [now],
        orderBy: 'next_review ASC');
  }

  Future<void> addToReviewQueue({
    required int attemptId,
    required String questionId,
    required String errorType,
  }) async {
    final db = await database;
    final nextReview = DateTime.now()
        .add(const Duration(hours: 4))
        .toIso8601String();
    await db.insert('review_queue', {
      'attempt_id': attemptId,
      'question_id': questionId,
      'error_type': errorType,
      'next_review': nextReview,
    });
  }

  Future<void> updateReviewItem(int id, {bool mastered = false}) async {
    final db = await database;
    if (mastered) {
      await db.update('review_queue', {'mastered': 1}, where: 'id = ?', whereArgs: [id]);
    } else {
      final item = await db.query('review_queue', where: 'id = ?', whereArgs: [id]);
      if (item.isNotEmpty) {
        final count = (item.first['review_count'] as int) + 1;
        final intervals = [4, 12, 24, 72, 168, 336];
        final hours = intervals[count.clamp(0, intervals.length - 1)];
        final nextReview = DateTime.now().add(Duration(hours: hours)).toIso8601String();
        await db.update('review_queue', {
          'review_count': count,
          'next_review': nextReview,
        }, where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Future<void> unlockAchievement(String key) async {
    final db = await database;
    try {
      await db.insert('achievements', {
        'key': key,
        'unlocked_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<String>> getAchievements() async {
    final db = await database;
    final results = await db.query('achievements');
    return results.map((r) => r['key'] as String).toList();
  }
}
