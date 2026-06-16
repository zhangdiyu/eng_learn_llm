import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

class CuratedQuestionService {
  List<GeneratedQuestion>? _cached;

  Future<List<GeneratedQuestion>> loadQuestions() async {
    if (_cached != null) return _cached!;
    final jsonStr = await rootBundle.loadString('assets/data/curated_questions.json');
    final list = jsonDecode(jsonStr) as List;
    _cached = list.map((e) => GeneratedQuestion.fromJson(e as Map<String, dynamic>)).toList();
    return _cached!;
  }

  List<GeneratedQuestion> getQuestionsByLevel(String level) {
    if (_cached == null) return [];
    return _cached!.where((q) => q.level == level).toList();
  }

  List<GeneratedQuestion> getQuestionsByTopic(String topic) {
    if (_cached == null) return [];
    return _cached!.where((q) => q.topic == topic).toList();
  }
}
