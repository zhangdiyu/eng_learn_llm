import 'package:flutter/foundation.dart';

/// Compile-time and runtime platform defaults.
///
/// By default:
/// - Android and Windows prefer the bundled local model
/// - Web uses the DeepSeek API
///
/// Optional override:
/// `--dart-define=ENABLE_LOCAL_LLM=true|false`
class BuildConfig {
  static const _explicitLocalLlm =
      String.fromEnvironment('ENABLE_LOCAL_LLM', defaultValue: '');

  static bool get enableLocalLlm {
    if (_explicitLocalLlm.isNotEmpty) {
      return _explicitLocalLlm.toLowerCase() == 'true';
    }
    return preferLocalLlm;
  }

  static bool get preferLocalLlm {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool get useDsApiByDefault => kIsWeb;

  static bool get requiresApiKey => useDsApiByDefault;
}
