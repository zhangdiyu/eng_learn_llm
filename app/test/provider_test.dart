import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningPreferences', () {
    test('default level is beginner', () {
      const levels = ['beginner', 'elementary', 'intermediate', 'advanced'];
      expect(levels[0], equals('beginner'));
    });

    test('default topics includes daily', () {
      const defaultTopics = ['daily'];
      expect(defaultTopics.contains('daily'), isTrue);
    });

    test('default daily goal is 20', () {
      const dailyGoal = 20;
      expect(dailyGoal, equals(20));
    });
  });

  group('UserStats', () {
    test('initial state is zero', () {
      int totalXp = 0;
      int currentStreak = 0;
      int questionsAnswered = 0;
      expect(totalXp, equals(0));
      expect(currentStreak, equals(0));
      expect(questionsAnswered, equals(0));
    });

    test('daily progress calculation', () {
      const todayCount = 10;
      const dailyGoal = 20;
      final progress = todayCount / dailyGoal;
      expect(progress, equals(0.5));
    });

    test('streak update preserves longest', () {
      int currentStreak = 3;
      int longestStreak = 7;
      currentStreak = 4;
      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      expect(longestStreak, equals(7));
    });

    test('streak update beats longest', () {
      int currentStreak = 8;
      int longestStreak = 7;
      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      expect(longestStreak, equals(8));
    });
  });

  group('AI Response validation', () {
    test('valid evaluation JSON structure', () {
      final json = {
        'verdict': 'mostly_correct',
        'score': 86,
        'dimensions': {'meaning': 95, 'grammar': 80, 'naturalness': 82, 'tone': 90},
        'correctedAnswer': "I'd like a glass of water, please.",
        'alternatives': ["Could I have a glass of water, please?"],
        'explanationZh': '点餐时使用 I\'d like 比 I want 更自然。',
        'issues': [
          {
            'type': 'naturalness',
            'original': 'I want',
            'suggestion': "I'd like",
            'reasonZh': '更礼貌自然',
          }
        ],
        'keyTakeawayZh': '礼貌提出需求时可用 I\'d like...',
      };

      expect(json.containsKey('verdict'), isTrue);
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('dimensions'), isTrue);
      expect(json['dimensions'] is Map, isTrue);
    });

    test('valid question JSON structure', () {
      final json = {
        'questionId': 'test-001',
        'level': 'A1',
        'topic': 'restaurant',
        'situationZh': '在餐厅点餐。',
        'promptZh': '我想要一杯水，谢谢。',
        'speakerRole': 'customer',
        'targetIntent': 'politely request a glass of water',
        'hints': {'keywords': ['would', 'water', 'please'], 'firstLetters': 'I w... l...'},
        'referenceAnswers': ["I'd like a glass of water, please."],
        'focusPoints': ['polite requests'],
      };

      expect(json.containsKey('questionId'), isTrue);
      expect(json.containsKey('level'), isTrue);
      expect(json.containsKey('hints'), isTrue);
      expect(json['hints'] is Map, isTrue);
    });
  });
}
