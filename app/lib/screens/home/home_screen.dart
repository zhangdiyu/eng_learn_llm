import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/learning.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _topicIcons = {
    LearningTopic.travel: Icons.flight,
    LearningTopic.work: Icons.work,
    LearningTopic.socialLife: Icons.people,
    LearningTopic.shopping: Icons.shopping_bag,
    LearningTopic.dining: Icons.restaurant,
    LearningTopic.daily: Icons.wb_sunny,
  };

  static const _topicLabels = {
    LearningTopic.travel: '旅行',
    LearningTopic.work: '工作',
    LearningTopic.socialLife: '社交',
    LearningTopic.shopping: '购物',
    LearningTopic.dining: '餐饮',
    LearningTopic.daily: '日常',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final prefs = ref.watch(preferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily English Quest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(stats, prefs, theme),
            const SizedBox(height: 24),
            _buildContinueButton(context, prefs),
            const SizedBox(height: 24),
            Text('选择主题', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTopicGrid(context, prefs),
            const SizedBox(height: 24),
            _buildQuickActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserStats stats, LearningPreferences prefs, ThemeData theme) {
    final progress = stats.dailyProgress.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.bolt, value: '${stats.totalXp}', label: '总 XP'),
                _StatItem(icon: Icons.local_fire_department, value: '${stats.currentStreak}', label: '连续天数'),
                _StatItem(icon: Icons.emoji_events, value: '${stats.longestStreak}', label: '最长记录'),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日目标 ${stats.todayCount}/${prefs.dailyGoal}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, LearningPreferences prefs) {
    final topic = prefs.topics.first;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push('/session', extra: {
          'topic': topic.name,
          'level': prefs.levelLabel,
        }),
        icon: const Icon(Icons.play_arrow),
        label: Text('继续学习 - ${_topicLabels[topic]}'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTopicGrid(BuildContext context, LearningPreferences prefs) {
    final topics = prefs.topics.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return Card(
          child: InkWell(
            onTap: () => context.push('/session', extra: {
              'topic': topic.name,
              'level': prefs.levelLabel,
            }),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_topicIcons[topic], size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(_topicLabels[topic] ?? '', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷操作', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/review'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.auto_fix_high, color: theme.colorScheme.secondary),
                        const SizedBox(height: 8),
                        Text('复习错题', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/session', extra: {
                    'topic': 'daily',
                    'level': 'daily_challenge',
                  }),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.stars, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text('每日挑战', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
