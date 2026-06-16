import '../models/question.dart';
import '../models/evaluation.dart';
import 'ai_provider.dart';

/// Web / no-local-LLM builds: stub implementation, never loaded at runtime.
class LocalAiProvider implements AiProvider {
  LocalAiProvider();

  bool get isLoaded => false;

  Future<void> loadModel(String modelPath) async {
    throw UnsupportedError('Local LLM is not enabled in this build.');
  }

  Future<void> unloadModel() async {}

  @override
  Future<GeneratedQuestion> generateQuestion(QuestionRequest request) async {
    throw UnsupportedError('Local LLM is not enabled in this build.');
  }

  @override
  Future<AnswerEvaluation> evaluateAnswer(EvaluationRequest request) async {
    throw UnsupportedError('Local LLM is not enabled in this build.');
  }

  @override
  Future<bool> testConnection() async => false;
}
