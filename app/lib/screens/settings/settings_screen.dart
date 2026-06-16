import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/learning.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final stats = ref.watch(statsProvider);
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
          _buildSection(theme, 'API 设置'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('API 密钥'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/api-setup'),
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
            'Daily English Quest v1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
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
