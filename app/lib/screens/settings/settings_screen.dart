import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/build_config.dart';
import '../../models/learning.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final stats = ref.watch(statsProvider);
    final useLocal = ref.watch(useLocalModelProvider);
    final localLoaded = ref.watch(localModelLoadedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(theme, '学习统计'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statRow('总经验值', '${stats.totalXp} XP', Icons.bolt),
                  const Divider(),
                  _statRow('连续学习', '${stats.currentStreak} 天', Icons.local_fire_department),
                  const Divider(),
                  _statRow('最长记录', '${stats.longestStreak} 天', Icons.emoji_events),
                  const Divider(),
                  _statRow('总答题数', '${stats.questionsAnswered}', Icons.quiz),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(theme, '学习设置'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('当前水平'),
                  trailing: DropdownButton<String>(
                    value: prefs.levelLabel,
                    items: const [
                      DropdownMenuItem(value: 'A1', child: Text('A1 入门')),
                      DropdownMenuItem(value: 'A2', child: Text('A2 初级')),
                      DropdownMenuItem(value: 'B1', child: Text('B1 中级')),
                      DropdownMenuItem(value: 'B2', child: Text('B2 高级')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        final level = {
                          'A1': ProficiencyLevel.beginner,
                          'A2': ProficiencyLevel.elementary,
                          'B1': ProficiencyLevel.intermediate,
                          'B2': ProficiencyLevel.advanced,
                        }[v]!;
                        ref.read(preferencesProvider.notifier).setLevel(level);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: const Text('音效'),
                  value: prefs.soundEnabled,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).setSoundEnabled(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('震动'),
                  value: prefs.vibrationEnabled,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).setVibrationEnabled(v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('每日目标'),
                  trailing: DropdownButton<int>(
                    value: prefs.dailyGoal,
                    items: [10, 20, 30, 50].map((g) => DropdownMenuItem(value: g, child: Text('$g 题'))).toList(),
                    onChanged: (v) {
                      if (v != null) ref.read(preferencesProvider.notifier).setDailyGoal(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(theme, 'AI 模型'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('DeepSeek API 密钥'),
                  subtitle: const Text('在线模型，需要网络和 API 余额'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/api-setup'),
                ),
                const Divider(height: 1),
                if (BuildConfig.enableLocalLlm) ...[
                  SwitchListTile(
                    secondary: Icon(Icons.phone_android, color: theme.colorScheme.secondary),
                    title: const Text('使用本地模型'),
                    subtitle: Text(_downloading
                        ? '下载中 ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                        : localLoaded
                            ? '模型已就绪 (Qwen2.5-1.5B ~986MB)'
                            : '首次使用需从安装包解压模型 (~986MB)'),
                    value: useLocal,
                    onChanged: _downloading
                        ? null
                        : (v) async {
                            if (v && !localLoaded) {
                              final ok = await _loadLocalModel();
                              if (!ok) return;
                            }
                            ref.read(useLocalModelProvider.notifier).state = v;
                          },
                  ),
                  if (_downloading) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LinearProgressIndicator(value: _downloadProgress),
                    ),
                  ],
                  if (localLoaded) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('本地模型已加载'),
                      subtitle: const Text('Qwen2.5-1.5B Q4_K_M (~986MB)'),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(theme, 'ChatTTS 语音'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.record_voice_over),
                  title: const Text('ChatTTS 服务地址'),
                  subtitle: const Text('自建 ChatTTS API，用于朗读参考回答'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChatTTSSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(theme, '数据管理'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('导出学习数据'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('重置所有数据', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('重置数据'),
                        content: const Text('确定要删除所有学习数据吗？此操作不可撤销。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(storageServiceProvider).clearAll();
                      if (context.mounted) context.go('/onboarding');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Daily English Quest v1.1.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<bool> _loadLocalModel() async {
    final modelManager = ref.read(modelManagerProvider);
    final localProvider = ref.read(localAiProviderProvider);
    if (modelManager == null || localProvider == null) {
      return false;
    }

    try {
      setState(() {
        _downloading = true;
        _downloadProgress = 0;
      });

      final modelPath = await modelManager.extractModelFromAssets(
        onProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
      );

      await localProvider.loadModel(modelPath);
      ref.read(localModelLoadedProvider.notifier).state = true;
      setState(() => _downloading = false);
      return true;
    } catch (e) {
      setState(() => _downloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模型加载失败: $e')),
        );
      }
      return false;
    }
  }

  void _showChatTTSSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ChatTTS 设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ChatTTS 需要自建服务端。'),
            SizedBox(height: 12),
            Text('部署方式:'),
            Text('1. pip install ChatTTS fastapi uvicorn'),
            Text('2. 启动 API 服务，监听 POST /tts'),
            Text('3. 在 App 中填入服务地址'),
            SizedBox(height: 12),
            Text('示例地址: http://192.168.1.100:8000'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
