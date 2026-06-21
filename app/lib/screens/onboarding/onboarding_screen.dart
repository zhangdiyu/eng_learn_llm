import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/build_config.dart';
import '../../models/learning.dart';
import '../../providers/preferences_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _topicLabels = {
    LearningTopic.travel: '旅行',
    LearningTopic.work: '工作',
    LearningTopic.socialLife: '社交',
    LearningTopic.shopping: '购物',
    LearningTopic.dining: '餐饮',
    LearningTopic.daily: '日常',
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(theme),
                  _buildLevelPage(theme),
                  _buildTopicPage(theme),
                  _buildReadyPage(theme),
                ],
              ),
            ),
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text('Daily English Quest', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            '通过 AI 对话练习，让日常英语变得自然流畅',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPage(ThemeData theme) {
    final prefs = ref.watch(preferencesProvider);
    final levels = [
      (ProficiencyLevel.beginner, 'A1 入门', '简短句子，现在时，熟悉词汇'),
      (ProficiencyLevel.elementary, 'A2 初级', '一到两句，基本时态，日常场景'),
      (ProficiencyLevel.intermediate, 'B1 中级', '多轮对话，礼貌语气，短语动词'),
      (ProficiencyLevel.advanced, 'B2 高级', '复杂场景，间接表达，职场沟通'),
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('选择你的水平', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ...levels.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LevelCard(
                  level: l.$1,
                  title: l.$2,
                  subtitle: l.$3,
                  isSelected: prefs.level == l.$1,
                  onTap: () => ref.read(preferencesProvider.notifier).setLevel(l.$1),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTopicPage(ThemeData theme) {
    final prefs = ref.watch(preferencesProvider);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('选择学习目标', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: LearningTopic.values.map((t) {
              final selected = prefs.topics.contains(t);
              return FilterChip(
                label: Text(_topicLabels[t] ?? t.name),
                selected: selected,
                onSelected: (_) => ref.read(preferencesProvider.notifier).toggleTopic(t),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: selected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPage(ThemeData theme) {
    final message = BuildConfig.requiresApiKey
        ? '接下来设置你的 AI 接口密钥，\n就可以开始学习了'
        : '本地模型将在设备上默认启用，\n你现在就可以开始学习了';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text('准备就绪！', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
            child: const Text('上一步'),
          ),
          Row(
            children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == i ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                ),
              )),
          ),
          _currentPage < 3
              ? TextButton(
                  onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: const Text('下一步'),
                )
              : FilledButton(
                  onPressed: () =>
                      context.go(BuildConfig.requiresApiKey ? '/api-setup' : '/'),
                  child: Text(BuildConfig.requiresApiKey ? '设置 API' : '开始学习'),
                ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ProficiencyLevel level;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
