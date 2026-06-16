import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/question.dart';
import '../../models/evaluation.dart';
import '../../config/theme.dart';

class FeedbackScreen extends StatelessWidget {
  final AnswerEvaluation evaluation;
  final String userAnswer;
  final GeneratedQuestion question;

  const FeedbackScreen({
    super.key,
    required this.evaluation,
    required this.userAnswer,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('答题反馈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVerdictCard(theme, colors),
            const SizedBox(height: 16),
            _buildScoreBreakdown(theme, colors),
            const SizedBox(height: 16),
            _buildAnswerComparison(theme, colors),
            const SizedBox(height: 16),
            if (evaluation.issues.isNotEmpty) _buildIssuesCard(theme),
            if (evaluation.issues.isNotEmpty) const SizedBox(height: 16),
            _buildExplanationCard(theme),
            const SizedBox(height: 16),
            _buildKeyTakeaway(theme),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一题'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictCard(ThemeData theme, AppColors colors) {
    final verdictConfig = _verdictDisplay(evaluation.verdict, colors);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(verdictConfig.icon, size: 64, color: verdictConfig.color),
            const SizedBox(height: 16),
            Text(
              verdictConfig.label,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: verdictConfig.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '得分 ${evaluation.score}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: verdictConfig.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(ThemeData theme, AppColors colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('详细评分', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _dimensionBar('语义', evaluation.dimensions.meaning, theme.colorScheme.primary),
            _dimensionBar('语法', evaluation.dimensions.grammar, colors.secondary),
            _dimensionBar('自然度', evaluation.dimensions.naturalness, colors.warning),
            _dimensionBar('语气', evaluation.dimensions.tone, colors.success),
          ],
        ),
      ),
    );
  }

  Widget _dimensionBar(String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('$score', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildAnswerComparison(ThemeData theme, AppColors colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你的回答', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _answerBgColor(colors).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(userAnswer, style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(height: 16),
            Text('推荐回答', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(evaluation.correctedAnswer, style: theme.textTheme.bodyLarge),
            ),
            if (evaluation.alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('其他说法', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ...evaluation.alternatives.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(a, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Color _answerBgColor(AppColors colors) {
    switch (evaluation.verdict) {
      case 'correct':
        return colors.success;
      case 'mostly_correct':
        return colors.warning;
      default:
        return colors.error;
    }
  }

  Widget _buildIssuesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('问题点', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...evaluation.issues.map((issue) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _issueColor(issue.type).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_issueLabel(issue.type),
                                style: TextStyle(fontSize: 12, color: _issueColor(issue.type))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'You wrote ', style: TextStyle(color: Colors.red)),
                            TextSpan(text: '"${issue.original}"', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
                            const TextSpan(text: ' → '),
                            TextSpan(text: '"${issue.suggestion}"', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(issue.reasonZh,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('中文解释', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(evaluation.explanationZh, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyTakeaway(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(60),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                evaluation.keyTakeawayZh,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color, String label}) _verdictDisplay(String verdict, AppColors colors) {
    switch (verdict) {
      case 'correct':
        return (icon: Icons.check_circle, color: colors.success, label: '完全正确');
      case 'mostly_correct':
        return (icon: Icons.check_circle_outline, color: colors.warning, label: '基本正确');
      case 'needs_revision':
        return (icon: Icons.refresh, color: colors.error, label: '需要修改');
      default:
        return (icon: Icons.replay, color: colors.error, label: '建议重试');
    }
  }

  Color _issueColor(String type) {
    switch (type) {
      case 'grammar':
        return Colors.red;
      case 'naturalness':
        return Colors.orange;
      case 'tone':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _issueLabel(String type) {
    switch (type) {
      case 'grammar':
        return '语法';
      case 'naturalness':
        return '自然度';
      case 'tone':
        return '语气';
      default:
        return '其他';
    }
  }
}
