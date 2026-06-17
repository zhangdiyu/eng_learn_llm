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
  bool _translationMode = false;
  bool _navigatingToFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(gameProvider(null).notifier);
      notifier.setTranslationMode(_translationMode);
      notifier.startSession(widget.topic, widget.level);
    });
  }

  void _toggleMode() {
    setState(() {
      _translationMode = !_translationMode;
      ref.read(gameProvider(null).notifier).setTranslationMode(_translationMode);
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
    _navigatingToFeedback = false;
    ref.read(gameProvider(null).notifier).submitAnswer(answer);
    _answerController.clear();
  }

  /// Navigate to feedback, then auto-advance on return
  Future<void> _goToFeedback(GameState game) async {
    if (_navigatingToFeedback) return;
    _navigatingToFeedback = true;

    ref.read(statsProvider.notifier).addXp(_calculateXp(game));
    await context.push('/feedback', extra: {
      'evaluation': game.lastEvaluation,
      'userAnswer': game.lastUserAnswer,
      'question': game.currentQuestion,
    });
    _navigatingToFeedback = false;

    if (mounted) {
      ref.read(gameProvider(null).notifier).nextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider(null));
    final theme = Theme.of(context);

    ref.listen<GameState>(gameProvider(null), (prev, next) {
      // Navigate to feedback when evaluation is done (even if errored)
      if (!next.isSubmitting &&
          prev?.isSubmitting == true &&
          next.lastEvaluation != null &&
          next.currentQuestion != null &&
          !_navigatingToFeedback) {
        _goToFeedback(next);
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
          ActionChip(
            avatar: Icon(
              _translationMode ? Icons.translate : Icons.chat,
              size: 18,
            ),
            label: Text(_translationMode ? '翻译' : '对话'),
            onPressed: _toggleMode,
          ),
          const SizedBox(width: 8),
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
                      label: const Text('Hint'),
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
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(gameProvider(null).notifier).skipQuestion(),
                child: const Text('Skip (-1 ❤️)', style: TextStyle(color: Colors.grey)),
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
    final text = question.situationEn.isNotEmpty
        ? question.situationEn
        : question.situationZh;
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
                text,
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
    final text = question.promptEn.isNotEmpty
        ? question.promptEn
        : question.promptZh;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              text,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Answer in English',
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
                Text('Hints', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber[700])),
              ],
            ),
            const SizedBox(height: 12),
            if (question.hints.keywords.isNotEmpty) ...[
              Text('Keywords:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
              Text('First letters: ${question.hints.firstLetters}',
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
        hintText: 'Type your answer in English...',
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
      'travel': 'Travel', 'work': 'Work', 'socialLife': 'Social',
      'shopping': 'Shopping', 'dining': 'Dining', 'daily': 'Daily',
    };
    return labels[widget.topic] ?? widget.topic;
  }
}
