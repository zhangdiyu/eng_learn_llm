class AppConfig {
  AppConfig._();

  static const String appName = 'Daily English Quest';
  static const String appVersion = '1.0.0';

  // AI Provider
  static const String aiBaseUrl = 'https://api.deepseek.com';
  static const String aiEndpoint = '/chat/completions';
  static const String aiModel = 'deepseek-v4-flash';
  static const Duration aiTimeout = Duration(seconds: 30);
  static const int aiMaxRetries = 1;
  static const int maxInputTokens = 2000;
  static const int maxOutputTokens = 1000;

  // Learning
  static const int prefetchQuestionCount = 2;
  static const int cachedQuestionsMin = 10;
  static const int heartsMax = 5;
  static const int heartsRegenMinutes = 30;
  static const int dailyGoalQuestions = 20;
  static const int streakProtectionThreshold = 7;

  // Scoring weights
  static const double meaningWeight = 0.45;
  static const double grammarWeight = 0.25;
  static const double naturalnessWeight = 0.20;
  static const double toneWeight = 0.10;
}
