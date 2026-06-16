import 'question.dart';

class AnswerEvaluation {
  final String verdict;
  final int score;
  final EvaluationDimensions dimensions;
  final String correctedAnswer;
  final List<String> alternatives;
  final String explanationZh;
  final List<EvaluationIssue> issues;
  final String keyTakeawayZh;

  const AnswerEvaluation({
    required this.verdict,
    required this.score,
    required this.dimensions,
    required this.correctedAnswer,
    required this.alternatives,
    required this.explanationZh,
    required this.issues,
    required this.keyTakeawayZh,
  });

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluation(
      verdict: json['verdict'] as String,
      score: json['score'] as int,
      dimensions: EvaluationDimensions.fromJson(
          json['dimensions'] as Map<String, dynamic>),
      correctedAnswer: json['correctedAnswer'] as String,
      alternatives: List<String>.from(json['alternatives'] as List),
      explanationZh: json['explanationZh'] as String,
      issues: (json['issues'] as List)
          .map((e) => EvaluationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      keyTakeawayZh: json['keyTakeawayZh'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'verdict': verdict,
        'score': score,
        'dimensions': dimensions.toJson(),
        'correctedAnswer': correctedAnswer,
        'alternatives': alternatives,
        'explanationZh': explanationZh,
        'issues': issues.map((e) => e.toJson()).toList(),
        'keyTakeawayZh': keyTakeawayZh,
      };
}

class EvaluationDimensions {
  final int meaning;
  final int grammar;
  final int naturalness;
  final int tone;

  const EvaluationDimensions({
    required this.meaning,
    required this.grammar,
    required this.naturalness,
    required this.tone,
  });

  factory EvaluationDimensions.fromJson(Map<String, dynamic> json) {
    return EvaluationDimensions(
      meaning: json['meaning'] as int,
      grammar: json['grammar'] as int,
      naturalness: json['naturalness'] as int,
      tone: json['tone'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'meaning': meaning,
        'grammar': grammar,
        'naturalness': naturalness,
        'tone': tone,
      };
}

class EvaluationIssue {
  final String type;
  final String original;
  final String suggestion;
  final String reasonZh;

  const EvaluationIssue({
    required this.type,
    required this.original,
    required this.suggestion,
    required this.reasonZh,
  });

  factory EvaluationIssue.fromJson(Map<String, dynamic> json) {
    return EvaluationIssue(
      type: json['type'] as String,
      original: json['original'] as String,
      suggestion: json['suggestion'] as String,
      reasonZh: json['reasonZh'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'original': original,
        'suggestion': suggestion,
        'reasonZh': reasonZh,
      };
}

class EvaluationRequest {
  final GeneratedQuestion question;
  final String userAnswer;

  const EvaluationRequest({
    required this.question,
    required this.userAnswer,
  });
}
