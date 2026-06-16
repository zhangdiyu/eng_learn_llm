import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManager {
  static const String defaultModelName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

  // Android native assets (only in APK, not web)
  static const String _androidAssetPath = 'models/$defaultModelName';

  static const String _prefsModelPath = 'local_model_path';
  static const String _prefsModelReady = 'local_model_ready';

  Future<String> getModelDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<String> getModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsModelPath);
    if (saved != null && File(saved).existsSync()) {
      return saved;
    }
    final dir = await getModelDir();
    return '$dir/$defaultModelName';
  }

  Future<bool> isModelReady() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsModelReady) == true) {
      final path = await getModelPath();
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  /// Extract model from Android native assets (via MethodChannel) to app documents.
  /// Only works on Android; the model is bundled in android/app/src/main/assets/.
  Future<String> extractModelFromAssets({
    void Function(double progress)? onProgress,
  }) async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await _markReady();
      return path;
    }

    try {
      final channel = const MethodChannel('com.dailyenglishquest/model');
      final success = await channel.invokeMethod<bool>('extractModel', {
        'assetPath': _androidAssetPath,
        'outputPath': path,
      });

      if (success == true && await file.exists()) {
        if (onProgress != null) onProgress(1.0);
        await _markReady();
        return path;
      }
    } on MissingPluginException {
      // MethodChannel not available (not Android)
    }

    throw StateError('Model not found. Run on Android to extract from APK.');
  }

  Future<void> _markReady() async {
    final prefs = await SharedPreferences.getInstance();
    final path = await getModelPath();
    await prefs.setString(_prefsModelPath, path);
    await prefs.setBool(_prefsModelReady, true);
  }

  Future<void> deleteModel() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsModelPath);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove(_prefsModelPath);
    await prefs.setBool(_prefsModelReady, false);
  }
}
