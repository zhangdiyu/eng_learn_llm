class ModelManager {
  static const String defaultModelName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

  Future<String> getModelDir() async =>
      throw UnsupportedError('Local LLM is not enabled in this build.');

  Future<String> getModelPath() async => '';

  Future<bool> isModelReady() async => false;

  Future<String> extractModelFromAssets({
    void Function(double progress)? onProgress,
  }) async =>
      throw UnsupportedError('Local LLM is not enabled in this build.');

  Future<void> deleteModel() async {}
}
