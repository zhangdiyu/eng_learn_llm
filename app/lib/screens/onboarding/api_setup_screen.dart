import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ApiSetupScreen extends ConsumerStatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  ConsumerState<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends ConsumerState<ApiSetupScreen> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _testResult = '请先输入 API 密钥');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    await ref.read(storageServiceProvider).saveApiKey(key);
    ref.invalidate(aiProviderProvider);

    try {
      final provider = ref.read(aiProviderProvider);
      final ok = await provider.testConnection();
      setState(() => _testResult = ok ? '连接成功！' : '连接失败，请检查密钥');
    } catch (e) {
      setState(() => _testResult = '连接失败：${e.toString()}');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _testResult = '请输入 API 密钥');
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(storageServiceProvider).saveApiKey(key);
    ref.invalidate(hasApiKeyProvider);
    setState(() => _isSaving = false);

    if (mounted) context.go('/');
  }

  Future<void> _deleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 API 密钥'),
        content: const Text('确定要删除保存的 API 密钥吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(storageServiceProvider).deleteApiKey();
      _keyController.clear();
      setState(() => _testResult = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('API 设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.vpn_key_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              '设置你的 DeepSeek API 密钥',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '密钥安全存储在你的设备上，不会上传到任何第三方服务器',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'API 密钥',
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('测试连接'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('保存并开始'),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.contains('成功')
                      ? Colors.green.withAlpha(20)
                      : Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _testResult!.contains('成功') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _deleteKey,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('删除保存的密钥', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('隐私与费用说明', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 你的问题内容将发送到 DeepSeek API 进行处理\n'
                    '• API 调用将消耗你的 DeepSeek 账户余额\n'
                    '• 密钥仅存储在设备本地，不会上传到我们的服务器\n'
                    '• 如需更多控制，未来可切换到托管网关',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
