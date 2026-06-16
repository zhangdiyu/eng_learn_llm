/// Compile-time flags passed via --dart-define.
///
/// APK:  --dart-define=ENABLE_LOCAL_LLM=true
/// Web:  --dart-define=ENABLE_LOCAL_LLM=false (default)
class BuildConfig {
  static const enableLocalLlm = bool.fromEnvironment(
    'ENABLE_LOCAL_LLM',
    defaultValue: false,
  );
}
