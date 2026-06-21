import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/opening_experience.dart';
import '../services/opening_experience_service.dart';
import 'auth_provider.dart';
import 'preferences_provider.dart';
import 'stats_provider.dart';

final openingExperienceServiceProvider =
    Provider<OpeningExperienceService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OpeningExperienceService(storage);
});

final openingCardProvider = FutureProvider<OpeningCardData?>((ref) async {
  final preferences = ref.watch(preferencesProvider);
  final stats = ref.watch(statsProvider);
  final service = ref.watch(openingExperienceServiceProvider);
  final hasApiKey = await ref.watch(hasApiKeyProvider.future);
  final useLocal = ref.watch(useLocalModelProvider);
  final localLoaded = ref.watch(localModelLoadedProvider);

  return service.getOpeningCard(
    preferences: preferences,
    stats: stats,
    localModelEnabled: useLocal,
    localModelLoaded: localLoaded,
    hasApiKey: hasApiKey,
  );
});
