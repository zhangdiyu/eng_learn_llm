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
    final messages = [
      _systemMessage(_questionSystemPrompt()),
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
You are an English conversation curriculum designer for Chinese learners.
Create exactly one practical daily-conversation exercise at the requested level and topic. The learner sees Chinese and must answer in English.

Requirements:
- Match vocabulary, grammar, sentence length, and social nuance to the level.
- Use realistic spoken English, not textbook-only phrasing.
- Include multiple acceptable reference answers.
- Avoid ambiguous Chinese prompts unless context resolves the ambiguity.
- Keep beginner hints useful without revealing the full answer.
- Return valid JSON matching the provided schema. Return no markdown.
Return JSON with fields: questionId, level, topic, situationZh, promptZh, speakerRole, targetIntent, hints{keywords[], firstLetters}, referenceAnswers[], focusPoints[]''';

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
