import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManager {
  static const String defaultModelName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

  // Accessed through AssetManager on Android.
  static const String _androidAssetPath =
      'flutter_assets/assets/models/$defaultModelName';

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

  /// Extract model from bundled assets into app documents.
  /// Android uses a MethodChannel; Windows copies from bundled Flutter assets.
  Future<String> extractModelFromAssets({
    void Function(double progress)? onProgress,
  }) async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await _markReady();
      return path;
    }

    if (Platform.isWindows) {
      await _copyWindowsBundledModel(file, onProgress: onProgress);
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
      // MethodChannel not available (for example desktop debug).
    }

    await _extractViaRootBundle(file, onProgress: onProgress);
    await _markReady();
    return path;
  }

  Future<void> _copyWindowsBundledModel(
    File outputFile, {
    void Function(double progress)? onProgress,
  }) async {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final candidates = <File>[
      File(p.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'models',
          defaultModelName)),
      File(p.join(Directory.current.path, 'data', 'flutter_assets', 'assets',
          'models', defaultModelName)),
    ];

    File? bundled;
    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        bundled = candidate;
        break;
      }
    }

    if (bundled == null) {
      await _extractViaRootBundle(outputFile, onProgress: onProgress);
      return;
    }

    await outputFile.parent.create(recursive: true);
    final total = await bundled.length();
    var written = 0;
    final sink = outputFile.openWrite();

    await for (final chunk in bundled.openRead()) {
      sink.add(chunk);
      written += chunk.length;
      onProgress?.call(total == 0 ? 0 : written / total);
    }

    await sink.close();
    onProgress?.call(1.0);
  }

  Future<void> _extractViaRootBundle(
    File outputFile, {
    void Function(double progress)? onProgress,
  }) async {
    final data = await rootBundle.load('assets/models/$defaultModelName');
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    onProgress?.call(1.0);
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
