import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/question.dart';
import '../models/evaluation.dart';

abstract interface class AiProvider {
  Future<GeneratedQuestion> generateQuestion(QuestionRequest request);
  Future<AnswerEvaluation> evaluateAnswer(EvaluationRequest request);
  Future<bool> testConnection();
}

class DeepSeekProvider implements AiProvider {
  final Dio _dio;
  final Future<String> Function() _getApiKey;

  DeepSeekProvider({required Future<String> Function() getApiKey})
      : _getApiKey = getApiKey,
        _dio = _createDio() {
    _setupInterceptors();
  }

  static Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: AppConfig.aiBaseUrl,
      connectTimeout: AppConfig.aiTimeout,
      receiveTimeout: AppConfig.aiTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final key = await _getApiKey();
        options.headers['Authorization'] = 'Bearer $key';
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  @override
  Future<GeneratedQuestion> generateQuestion(QuestionRequest request) async {
    final systemPrompt = request.translationMode
        ? _translationSystemPrompt()
        : _questionSystemPrompt();
    final messages = [
      _systemMessage(systemPrompt),
      _userMessage(jsonEncode(request.toJson())),
    ];

    final response = await _makeRequest(messages);
    final content = _extractJson(response);
    return GeneratedQuestion.fromJson(content);
  }

  @override
  Future<AnswerEvaluation> evaluateAnswer(EvaluationRequest request) async {
    final userMessage = jsonEncode({
      'question': request.question.toJson(),
      'userAnswer': request.userAnswer,
    });

    final messages = [
      _systemMessage(_evaluationSystemPrompt()),
      _userMessage(userMessage),
    ];

    final response = await _makeRequest(messages);
    final content = _extractJson(response);
    return AnswerEvaluation.fromJson(content);
  }

  @override
  Future<bool> testConnection() async {
    try {
      final messages = [
        _systemMessage('Reply with exactly: {"status":"ok"}'),
        _userMessage('ping'),
      ];
      final response = await _makeRequest(messages);
      final content = _extractJson(response);
      return content['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _makeRequest(List<Map<String, dynamic>> messages) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.post(
          AppConfig.aiEndpoint,
          data: {
            'model': AppConfig.aiModel,
            'messages': messages,
            'max_tokens': AppConfig.maxOutputTokens,
            'temperature': 0.7,
          },
        );
        return response.data as Map<String, dynamic>;
      } catch (e) {
        attempts++;
        if (attempts > AppConfig.aiMaxRetries) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Map<String, dynamic> _extractJson(Map<String, dynamic> response) {
    final choices = response['choices'] as List;
    final content = choices[0]['message']['content'] as String;
    final trimmed = content.trim();
    if (trimmed.startsWith('```')) {
      final start = trimmed.indexOf('\n');
      final end = trimmed.lastIndexOf('```');
      if (start != -1 && end != -1) {
        return jsonDecode(trimmed.substring(start, end).trim()) as Map<String, dynamic>;
      }
    }
    return jsonDecode(trimmed) as Map<String, dynamic>;
  }

  Map<String, dynamic> _systemMessage(String content) => {
        'role': 'system',
        'content': content,
      };

  Map<String, dynamic> _userMessage(String content) => {
        'role': 'user',
        'content': content,
      };

  String _questionSystemPrompt() => '''
You are an English conversation curriculum designer.
Create exactly one practical daily-conversation exercise at the requested level and topic.

The question MUST be presented in English (the situation and prompt the learner reads).
The learner answers in English.

Requirements:
- Match vocabulary, grammar, sentence length, and social nuance to the level.
- Use realistic spoken English, not textbook-only phrasing.
- Include multiple acceptable reference answers.
- Keep beginner hints useful without revealing the full answer.
- Return valid JSON matching the provided schema. Return no markdown.

JSON fields: questionId, level, topic, situationEn (English situation description), promptEn (the English question/prompt the learner must respond to), speakerRole, targetIntent, hints{keywords[], firstLetters}, referenceAnswers[], focusPoints[]

IMPORTANT: situationEn and promptEn must be in ENGLISH.''';

  String _translationSystemPrompt() => '''
You are an English translation exercise generator.
Create exactly one Chinese-to-English translation exercise at the requested level.

The learner sees a Chinese sentence and must translate it to natural English.

Requirements:
- Generate a practical, culturally neutral Chinese sentence appropriate for the level.
- The sentence should be something a Chinese speaker would naturally say in daily life.
- Provide 2-3 acceptable English translations as reference answers.
- Return valid JSON matching the provided schema. Return no markdown.

JSON fields: questionId, level, topic, situationZh (Chinese context/situation), promptZh (the Chinese sentence to translate), speakerRole, targetIntent, hints{keywords[], firstLetters}, referenceAnswers[], focusPoints[]

IMPORTANT: promptZh must be the Chinese sentence. referenceAnswers are the English translations.''';

  String _evaluationSystemPrompt() => '''
You are a fair English speaking and writing coach for Chinese learners.
Evaluate whether the learner's English communicates the target intent in the given situation.

Priority:
1. Meaning and task completion
2. Grammar
3. Naturalness
4. Tone and politeness

Accept valid alternatives and regional English. Do not require exact matching with a reference answer. Explain errors briefly in Chinese, provide a corrected answer, and include at most two natural alternatives. Return valid JSON matching the provided schema. Return no markdown.
Return JSON with fields: verdict (correct/mostly_correct/needs_revision/retry), score (0-100), dimensions{meaning, grammar, naturalness, tone}, correctedAnswer, alternatives[], explanationZh, issues[{type, original, suggestion, reasonZh}], keyTakeawayZh''';
}
