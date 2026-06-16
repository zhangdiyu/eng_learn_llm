import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../providers/stats_provider.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String topic;
  final String level;

  const SessionScreen({super.key, required this.topic, required this.level});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _answerController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider(null).notifier).startSession(widget.topic, widget.level);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    ref.read(gameProvider(null).notifier).submitAnswer(answer);
    _answerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider(null));
    final theme = Theme.of(context);

    ref.listen<GameState>(gameProvider(null), (prev, next) {
      if (next.lastEvaluation != null && next.currentQuestion != null) {
        ref.read(statsProvider.notifier).addXp(_calculateXp(next));
        context.push('/feedback', extra: {
          'evaluation': next.lastEvaluation,
          'userAnswer': next.lastUserAnswer,
          'question': next.currentQuestion,
        });
      }
    });

    if (game.isLoading && game.currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_topicLabel())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = game.currentQuestion;
    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_topicLabel())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('暂无题目', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(gameProvider(null).notifier).startSession(widget.topic, widget.level),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_topicLabel()),
        actions: [
          Row(
            children: List.generate(
              game.heartsRemaining,
              (_) => const Icon(Icons.favorite, color: Colors.red, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text('${game.sessionQuestionsAnswered + 1}', style: theme.textTheme.titleSmall),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSituationCard(question, theme),
              const SizedBox(height: 16),
              _buildPromptCard(question, theme),
              if (_showHints) ...[
                const SizedBox(height: 16),
                _buildHintsCard(question, theme),
              ],
              const SizedBox(height: 24),
              _buildAnswerInput(theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showHints = !_showHints),
                      icon: Icon(_showHints ? Icons.lightbulb : Icons.lightbulb_outline),
                      label: const Text('提示'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: game.isSubmitting ? null : _submitAnswer,
                      child: game.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('提交'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(gameProvider(null).notifier).skipQuestion(),
                child: const Text('跳过 (-1 ❤️)', style: TextStyle(color: Colors.grey)),
              ),
              if (game.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(game.error!, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSituationCard(question, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(60),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.place, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.situationZh,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(question.speakerRole, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(question, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              question.promptZh,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '请用英文回答',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintsCard(question, ThemeData theme) {
    return Card(
      color: Colors.amber.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text('提示', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber[700])),
              ],
            ),
            const SizedBox(height: 12),
            if (question.hints.keywords.isNotEmpty) ...[
              Text('关键词:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: question.hints.keywords
                    .map<Widget>((k) => Chip(
                          label: Text(k),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (question.hints.firstLetters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('首字母: ${question.hints.firstLetters}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(ThemeData theme) {
    return TextField(
      controller: _answerController,
      focusNode: _focusNode,
      maxLines: 3,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submitAnswer(),
      decoration: const InputDecoration(
        hintText: '在这里输入你的英文答案...',
        border: OutlineInputBorder(),
      ),
    );
  }

  int _calculateXp(GameState game) {
    int xp = 10;
    if (!_showHints) xp += 5;
    if (game.lastEvaluation?.score != null && game.lastEvaluation!.score >= 90) xp += 5;
    return xp;
  }

  String _topicLabel() {
    const labels = {
      'travel': '旅行英语', 'work': '工作英语', 'socialLife': '社交英语',
      'shopping': '购物英语', 'dining': '餐饮英语', 'daily': '日常英语',
    };
    return labels[widget.topic] ?? widget.topic;
  }
}
