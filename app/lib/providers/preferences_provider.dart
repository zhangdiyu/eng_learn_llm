import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class PreferencesNotifier extends StateNotifier<LearningPreferences> {
  final StorageService _storage;

  PreferencesNotifier(this._storage)
      : super(_storage.loadPreferences());

  void setLevel(ProficiencyLevel level) {
    state = state.copyWith(level: level);
    _storage.savePreferences(state);
  }

  void toggleTopic(LearningTopic topic) {
    final topics = Set<LearningTopic>.from(state.topics);
    if (topics.contains(topic)) {
      topics.remove(topic);
    } else {
      topics.add(topic);
    }
    state = state.copyWith(topics: topics);
    _storage.savePreferences(state);
  }

  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _storage.savePreferences(state);
  }

  void setVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
    _storage.savePreferences(state);
  }

  void setDailyGoal(int goal) {
    state = state.copyWith(dailyGoal: goal);
    _storage.savePreferences(state);
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, LearningPreferences>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PreferencesNotifier(storage);
});
