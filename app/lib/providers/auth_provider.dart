import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_provider.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final svc = StorageService();
  svc.init();
  return svc;
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

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
