import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/build_config.dart';
import '../models/question.dart';
import '../models/evaluation.dart';
import '../services/ai_provider.dart';
import '../services/local_ai_provider.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

class GameState {
  final GeneratedQuestion? currentQuestion;
  final List<GeneratedQuestion> prefetchedQuestions;
  final AnswerEvaluation? lastEvaluation;
  final String? lastUserAnswer;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int sessionQuestionsAnswered;
  final int heartsRemaining;
  final int? lastAttemptId;
  final bool usingLocalModel;
  final bool isTranslationMode;

  const GameState({
    this.currentQuestion,
    this.prefetchedQuestions = const [],
    this.lastEvaluation,
    this.lastUserAnswer,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.sessionQuestionsAnswered = 0,
    this.heartsRemaining = 5,
    this.lastAttemptId,
    this.usingLocalModel = false,
    this.isTranslationMode = false,
  });

  GameState copyWith({
    GeneratedQuestion? currentQuestion,
    List<GeneratedQuestion>? prefetchedQuestions,
    AnswerEvaluation? lastEvaluation,
    String? lastUserAnswer,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    int? sessionQuestionsAnswered,
    int? heartsRemaining,
    int? lastAttemptId,
    bool? usingLocalModel,
    bool? isTranslationMode,
    bool clearError = false,
    bool clearEvaluation = false,
  }) {
    return GameState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      prefetchedQuestions: prefetchedQuestions ?? this.prefetchedQuestions,
      lastEvaluation:
          clearEvaluation ? null : (lastEvaluation ?? this.lastEvaluation),
      lastUserAnswer:
          clearEvaluation ? null : (lastUserAnswer ?? this.lastUserAnswer),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      sessionQuestionsAnswered:
          sessionQuestionsAnswered ?? this.sessionQuestionsAnswered,
      heartsRemaining: heartsRemaining ?? this.heartsRemaining,
      lastAttemptId: lastAttemptId ?? this.lastAttemptId,
      usingLocalModel: usingLocalModel ?? this.usingLocalModel,
      isTranslationMode: isTranslationMode ?? this.isTranslationMode,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final AiProvider _cloudAi;
  final LocalAiProvider? _localAi;
  final StorageService _storage;
  final DatabaseService _db;

  GameNotifier(this._cloudAi, this._localAi, this._storage, this._db)
      : super(const GameState()) {
    _loadCachedQuestions();
  }

  AiProvider get _activeProvider {
    if (_localAi != null && _localAi.isLoaded) return _localAi;
    return _cloudAi;
  }

  bool get _isLocal => _activeProvider is LocalAiProvider;

  void setTranslationMode(bool enabled) {
    state = state.copyWith(isTranslationMode: enabled);
  }

  void _loadCachedQuestions() {
    final ids = _storage.getCachedQuestionIds();
    final questions = <GeneratedQuestion>[];
    for (final id in ids.take(2)) {
      final json = _storage.getCachedQuestion(id);
      if (json != null) {
        try {
          questions.add(GeneratedQuestion.fromJson(
              jsonDecode(json) as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    if (questions.isNotEmpty) {
      state = state.copyWith(
        currentQuestion: questions.first,
        prefetchedQuestions: questions.length > 1 ? questions.sublist(1) : [],
      );
    }
  }

  Future<void> startSession(String topic, String level) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      usingLocalModel: _isLocal,
    );
    try {
      final q1 = await _activeProvider.generateQuestion(QuestionRequest(
        level: level,
        topic: topic,
      ));
      _cacheQuestion(q1);

      GeneratedQuestion? q2;
      try {
        q2 = await _activeProvider.generateQuestion(QuestionRequest(
          level: level,
          topic: topic,
          recentQuestionIds: [q1.questionId],
        ));
        _cacheQuestion(q2);
      } catch (_) {}

      state = state.copyWith(
        currentQuestion: q1,
        prefetchedQuestions: q2 != null ? [q2] : [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _isLocal
            ? 'Failed to load local model. Check settings.'
            : 'Unable to generate question: ${e.toString()}',
      );
    }
  }

  Future<void> submitAnswer(String answer) async {
    if (state.currentQuestion == null) return;
    state = state.copyWith(isSubmitting: true, error: null);

    final question = state.currentQuestion!;

    // DB save may fail on web (sqflite not supported), ignore gracefully
    int attemptId = -1;
    try {
      attemptId = await _db.saveAttempt(
        questionId: question.questionId,
        questionJson: jsonEncode(question.toJson()),
        userAnswer: answer,
      );
    } catch (_) {}

    // Kick off next question generation IN PARALLEL with evaluation
    final nextFuture = _prefetchIfNeeded(force: true);

    try {
      final evaluation = await _activeProvider.evaluateAnswer(EvaluationRequest(
        question: question,
        userAnswer: answer,
      ));

      try {
        await _db.updateAttemptEvaluation(attemptId, evaluation);
        if (evaluation.verdict == 'needs_revision' || evaluation.score < 60) {
          for (final issue in evaluation.issues) {
            await _db.addToReviewQueue(
              attemptId: attemptId,
              questionId: question.questionId,
              errorType: issue.type,
            );
          }
        }
      } catch (_) {}

      await nextFuture;

      state = state.copyWith(
        isSubmitting: false,
        lastEvaluation: evaluation,
        lastUserAnswer: answer,
        lastAttemptId: attemptId,
        sessionQuestionsAnswered: state.sessionQuestionsAnswered + 1,
      );
    } catch (e) {
      await nextFuture;
      state = state.copyWith(
        isSubmitting: false,
        error: 'Evaluation failed: ${e.toString()}',
        lastUserAnswer: answer,
        lastAttemptId: attemptId,
        sessionQuestionsAnswered: state.sessionQuestionsAnswered + 1,
      );
    }
  }

  Future<void> nextQuestion() async {
    if (state.prefetchedQuestions.isNotEmpty) {
      final next = state.prefetchedQuestions.first;
      final remaining = state.prefetchedQuestions.sublist(1);
      state = state.copyWith(
        currentQuestion: next,
        prefetchedQuestions: remaining,
        lastEvaluation: null,
        lastUserAnswer: null,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: true,
        lastEvaluation: null,
        lastUserAnswer: null,
        error: null,
      );
      try {
        final question = state.currentQuestion!;
        final newQ = await _activeProvider.generateQuestion(QuestionRequest(
          level: question.level,
          topic: question.topic,
          recentQuestionIds: [question.questionId],
        ));
        _cacheQuestion(newQ);
        state = state.copyWith(
          currentQuestion: newQ,
          isLoading: false,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to generate next question.',
        );
      }
    }

    _prefetchIfNeeded();
  }

  Future<void> skipQuestion() async {
    state = state.copyWith(heartsRemaining: state.heartsRemaining - 1);
    await nextQuestion();
  }

  Future<void> _prefetchIfNeeded({bool force = false}) async {
    final target = force ? 3 : 2;
    if (state.prefetchedQuestions.length < target && state.currentQuestion != null) {
      try {
        final q = await _activeProvider.generateQuestion(QuestionRequest(
          level: state.currentQuestion!.level,
          topic: state.currentQuestion!.topic,
        ));
        _cacheQuestion(q);
        state = state.copyWith(
          prefetchedQuestions: [...state.prefetchedQuestions, q],
        );
      } catch (_) {}
    }
  }

  void _cacheQuestion(GeneratedQuestion q) {
    _storage.cacheQuestion(q.questionId, jsonEncode(q.toJson()));
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, void>((ref, _) {
  final cloudAi = ref.watch(aiProviderProvider);
  final localAi = BuildConfig.enableLocalLlm
      ? ref.watch(localAiProviderProvider)
      : null;
  final storage = ref.watch(storageServiceProvider);
  final db = ref.watch(databaseServiceProvider);
  return GameNotifier(cloudAi, localAi, storage, db);
});
