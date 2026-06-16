import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManager {
  static const String defaultModelName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';
  static const String _assetKey = 'assets/models/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

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

  /// Copy model from APK assets to app documents (one-time, ~986MB)
  Future<String> extractModelFromAssets({
    void Function(double progress)? onProgress,
  }) async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await _markReady();
      return path;
    }

    final data = await rootBundle.load(_assetKey);
    final dir = await getModelDir();
    final tmpPath = '$dir/_tmp_$defaultModelName';

    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(
      data.buffer.asUint8List(),
      flush: true,
    );
    await tmpFile.rename(path);

    if (onProgress != null) onProgress(1.0);
    await _markReady();
    return path;
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
