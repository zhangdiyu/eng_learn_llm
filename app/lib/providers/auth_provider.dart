import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/build_config.dart';
import '../services/ai_provider.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/local_ai_provider.dart';
import '../services/model_manager.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final svc = StorageService();
  svc.init();
  return svc;
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final modelManagerProvider = Provider<ModelManager?>((ref) {
  if (!BuildConfig.enableLocalLlm) return null;
  return ModelManager();
});

final localAiProviderProvider = Provider<LocalAiProvider?>((ref) {
  if (!BuildConfig.enableLocalLlm) return null;
  return LocalAiProvider();
});

final localModelLoadedProvider = StateProvider<bool>((ref) => false);

final aiProviderProvider = Provider<AiProvider>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DeepSeekProvider(
    getApiKey: () async => await storage.getApiKey() ?? '',
  );
});

final hasApiKeyProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.hasApiKey();
});

/// Returns true if we should use local model (no API key, but local model available)
final useLocalModelProvider = StateProvider<bool>((ref) => false);
