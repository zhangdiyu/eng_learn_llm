enum ProficiencyLevel { beginner, elementary, intermediate, advanced }

enum LearningTopic { travel, work, socialLife, shopping, dining, daily }

class LearningPreferences {
  final ProficiencyLevel level;
  final Set<LearningTopic> topics;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int dailyGoal;

  const LearningPreferences({
    this.level = ProficiencyLevel.beginner,
    this.topics = const {LearningTopic.daily},
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dailyGoal = 20,
  });

  String get levelLabel {
    switch (level) {
      case ProficiencyLevel.beginner:
        return 'A1';
      case ProficiencyLevel.elementary:
        return 'A2';
      case ProficiencyLevel.intermediate:
        return 'B1';
      case ProficiencyLevel.advanced:
        return 'B2';
    }
  }

  LearningPreferences copyWith({
    ProficiencyLevel? level,
    Set<LearningTopic>? topics,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? dailyGoal,
  }) {
    return LearningPreferences(
      level: level ?? this.level,
      topics: topics ?? this.topics,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

class UserStats {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int questionsAnswered;
  final int todayCount;

  const UserStats({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.questionsAnswered = 0,
    this.todayCount = 0,
  });

  UserStats copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    int? questionsAnswered,
    int? todayCount,
  }) {
    return UserStats(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      todayCount: todayCount ?? this.todayCount,
    );
  }

  double get dailyProgress => todayCount / 20;
}
