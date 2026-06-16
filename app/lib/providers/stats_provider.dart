import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class StatsNotifier extends StateNotifier<UserStats> {
  final StorageService _storage;

  StatsNotifier(this._storage) : super(_storage.loadStats());

  void addXp(int xp) {
    state = state.copyWith(
      totalXp: state.totalXp + xp,
      questionsAnswered: state.questionsAnswered + 1,
      todayCount: state.todayCount + 1,
    );
    _storage.saveStats(state);
  }

  void updateStreak(int streak) {
    final longest =
        streak > state.longestStreak ? streak : state.longestStreak;
    state = state.copyWith(
      currentStreak: streak,
      longestStreak: longest,
    );
    _storage.saveStats(state);
  }

  void resetToday() {
    state = state.copyWith(todayCount: 0);
    _storage.saveStats(state);
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, UserStats>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StatsNotifier(storage);
});
