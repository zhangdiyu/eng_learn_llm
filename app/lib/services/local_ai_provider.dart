import 'dart:convert';
import 'package:llamadart/llamadart.dart';
import '../models/question.dart';
import '../models/evaluation.dart';
import 'ai_provider.dart';

class LocalAiProvider implements AiProvider {
  LlamaEngine? _engine;
  ChatSession? _session;
  bool _isLoaded = false;

  LocalAiProvider();

  bool get isLoaded => _isLoaded;

  Future<void> loadModel(String modelPath) async {
    if (modelPath.isEmpty) {
      throw StateError('Model path is empty');
    }

    _engine = LlamaEngine(LlamaBackend());
    await _engine!.loadModel(
      modelPath,
      modelParams: const ModelParams(
        contextSize: 2048,
        batchSize: 512,
      ),
    );

    _session = ChatSession(
      _engine!,
      systemPrompt: _combinedSystemPrompt(),
    );

    _isLoaded = true;
  }

  Future<void> unloadModel() async {
    _isLoaded = false;
    _session = null;
    await _engine?.dispose();
    _engine = null;
  }

  @override
  Future<GeneratedQuestion> generateQuestion(QuestionRequest request) async {
    _ensureLoaded();
    final prompt = _questionPrompt(request.level, request.topic);
    final json = await _generateJson(prompt);
    return GeneratedQuestion.fromJson(json);
  }

  @override
  Future<AnswerEvaluation> evaluateAnswer(EvaluationRequest request) async {
    _ensureLoaded();
    final prompt = _evaluationPrompt(
      request.question.situationZh,
      request.question.promptZh,
      request.question.targetIntent,
      request.question.referenceAnswers.join(' | '),
      request.userAnswer,
    );
    final json = await _generateJson(prompt);
    return AnswerEvaluation.fromJson(json);
  }

  @override
  Future<bool> testConnection() async {
    try {
      _ensureLoaded();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _ensureLoaded() {
    if (!_isLoaded || _engine == null || _session == null) {
      throw StateError('Local model not loaded. Call loadModel() first.');
    }
  }

  Future<Map<String, dynamic>> _generateJson(String prompt) async {
    final buffer = StringBuffer();
    await for (final chunk in _session!.create(
      [LlamaTextContent(prompt)],
    )) {
      final delta = chunk.choices.first.delta;
      if (delta.content != null) {
        buffer.write(delta.content);
      }
    }

    var text = buffer.toString().trim();
    // Strip markdown fences
    if (text.startsWith('```')) {
      final start = text.indexOf('\n');
      final end = text.lastIndexOf('```');
      if (start != -1 && end != -1) {
        text = text.substring(start, end).trim();
      }
    }
    // Find the first { and last }
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1) {
      text = text.substring(firstBrace, lastBrace + 1);
    }

    return _parseJson(text);
  }

  Map<String, dynamic> _parseJson(String text) {
    // Try standard parse
    try {
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (_) {}

    // Repair common issues
    var repaired = text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('，', ',')
        .replaceAll('：', ':');

    repaired = repaired.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

    return Map<String, dynamic>.from(jsonDecode(repaired) as Map);
  }

  // --- Prompt builders ---

  String _combinedSystemPrompt() {
    return 'You are both an English conversation curriculum designer AND a fair English coach for Chinese learners.\n'
        'When asked to generate a question, create a practical daily-conversation exercise with a Chinese prompt, matching the requested level and topic. Use realistic spoken English.\n'
        'When asked to evaluate an answer, judge semantic correctness before exact wording. Accept contractions, regional variants, and natural alternatives. Explain errors briefly in Chinese.\n'
        'Always return ONLY valid JSON. No markdown, no extra text outside the JSON.';
  }

  String _questionPrompt(String level, String topic) {
    return 'Generate one practical daily English conversation exercise.\n'
        'Level: $level\n'
        'Topic: $topic\n'
        '\n'
        'Return ONLY valid JSON (no markdown):\n'
        '{\n'
        '  "questionId": "unique-id",\n'
        '  "level": "$level",\n'
        '  "topic": "$topic",\n'
        '  "situationZh": "Chinese situation description",\n'
        '  "promptZh": "Chinese sentence to translate",\n'
        '  "speakerRole": "speaker identity",\n'
        '  "targetIntent": "what the learner should express in English",\n'
        '  "hints": {"keywords": ["word1", "word2"], "firstLetters": "first letters hint"},\n'
        '  "referenceAnswers": ["answer1", "answer2"],\n'
        '  "focusPoints": ["grammar point", "vocab point"]\n'
        '}';
  }

  String _evaluationPrompt(
    String situationZh,
    String promptZh,
    String targetIntent,
    String referenceAnswers,
    String userAnswer,
  ) {
    return 'Evaluate this English learner\'s answer.\n'
        '\n'
        'Situation: $situationZh\n'
        'Prompt: $promptZh\n'
        'Target intent: $targetIntent\n'
        'Reference answers: $referenceAnswers\n'
        'User answer: "$userAnswer"\n'
        '\n'
        'Judge semantic correctness before exact wording. Accept contractions, regional variants, natural alternatives.\n'
        'Return ONLY valid JSON (no markdown):\n'
        '{\n'
        '  "verdict": "correct|mostly_correct|needs_revision|retry",\n'
        '  "score": 0-100,\n'
        '  "dimensions": {"meaning": 0-100, "grammar": 0-100, "naturalness": 0-100, "tone": 0-100},\n'
        '  "correctedAnswer": "best natural English version",\n'
        '  "alternatives": ["alternative 1", "alternative 2"],\n'
        '  "explanationZh": "brief Chinese explanation of errors or improvements",\n'
        '  "issues": [{"type": "grammar|naturalness|tone", "original": "user text", "suggestion": "improved text", "reasonZh": "Chinese reason"}],\n'
        '  "keyTakeawayZh": "one key learning point in Chinese"\n'
        '}';
  }
}
