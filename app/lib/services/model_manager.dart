import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManager {
  static const String defaultModelName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';
  static const String modelUrl =
      'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

  static const String _prefsModelPath = 'local_model_path';
  static const String _prefsModelDownloaded = 'local_model_downloaded';

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

  Future<bool> isModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsModelDownloaded) == true) {
      final path = await getModelPath();
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  Future<String> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) return path;

    final dio = Dio();
    await dio.download(
      modelUrl,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsModelPath, path);
    await prefs.setBool(_prefsModelDownloaded, true);

    return path;
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
    await prefs.setBool(_prefsModelDownloaded, false);
  }
}
