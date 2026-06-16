class GeneratedQuestion {
  final String questionId;
  final String level;
  final String topic;
  final String situationZh;
  final String promptZh;
  final String speakerRole;
  final String targetIntent;
  final QuestionHints hints;
  final List<String> referenceAnswers;
  final List<String> focusPoints;

  const GeneratedQuestion({
    required this.questionId,
    required this.level,
    required this.topic,
    required this.situationZh,
    required this.promptZh,
    required this.speakerRole,
    required this.targetIntent,
    required this.hints,
    required this.referenceAnswers,
    required this.focusPoints,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      questionId: json['questionId'] as String,
      level: json['level'] as String,
      topic: json['topic'] as String,
      situationZh: json['situationZh'] as String,
      promptZh: json['promptZh'] as String,
      speakerRole: json['speakerRole'] as String,
      targetIntent: json['targetIntent'] as String,
      hints: QuestionHints.fromJson(json['hints'] as Map<String, dynamic>),
      referenceAnswers: List<String>.from(json['referenceAnswers'] as List),
      focusPoints: List<String>.from(json['focusPoints'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'level': level,
        'topic': topic,
        'situationZh': situationZh,
        'promptZh': promptZh,
        'speakerRole': speakerRole,
        'targetIntent': targetIntent,
        'hints': hints.toJson(),
        'referenceAnswers': referenceAnswers,
        'focusPoints': focusPoints,
      };
}

class QuestionHints {
  final List<String> keywords;
  final String firstLetters;

  const QuestionHints({
    required this.keywords,
    required this.firstLetters,
  });

  factory QuestionHints.fromJson(Map<String, dynamic> json) {
    return QuestionHints(
      keywords: List<String>.from(json['keywords'] as List),
      firstLetters: json['firstLetters'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'keywords': keywords,
        'firstLetters': firstLetters,
      };
}

class QuestionRequest {
  final String level;
  final String topic;
  final List<String> recentQuestionIds;

  const QuestionRequest({
    required this.level,
    required this.topic,
    this.recentQuestionIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'topic': topic,
        'recentQuestionIds': recentQuestionIds,
      };
}
