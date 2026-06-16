import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Map<String, dynamic>> _reviewItems = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseServiceProvider);
    final items = await db.getReviewQueue();
    final history = await db.getAttemptHistory(limit: 50);
    if (mounted) {
      setState(() {
        _reviewItems = items;
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: '待复习 (${_reviewItems.length})'),
                      Tab(text: '历史记录 (${_history.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildReviewList(theme),
                        _buildHistoryList(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReviewList(ThemeData theme) {
    if (_reviewItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('没有待复习的题目', style: theme.textTheme.titleMedium),
            Text('完成更多练习后，错题会出现在这里', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviewItems.length,
      itemBuilder: (context, index) {
        final item = _reviewItems[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _errorColor(item['error_type'] as String).withAlpha(30),
              child: Icon(Icons.error_outline, color: _errorColor(item['error_type'] as String)),
            ),
            title: Text(item['question_id'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_errorLabel(item['error_type'] as String)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await ref.read(databaseServiceProvider).updateReviewItem(
                          item['id'] as int,
                          mastered: true,
                        );
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('还没有练习记录', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final score = item['score'] as int?;
        final verdict = item['verdict'] as String?;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _scoreColor(score).withAlpha(30),
              child: Text(score?.toString() ?? '?',
                  style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.bold)),
            ),
            title: Text('回答 ${_history.length - index}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(verdict ?? '未评分'),
            trailing: Icon(_verdictIcon(verdict), color: _scoreColor(score)),
          ),
        );
      },
    );
  }

  Color _scoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }

  Color _errorColor(String type) {
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

  String _errorLabel(String type) {
    switch (type) {
      case 'grammar':
        return '语法错误';
      case 'naturalness':
        return '表达不自然';
      case 'tone':
        return '语气不当';
      default:
        return '其他问题';
    }
  }

  IconData _verdictIcon(String? verdict) {
    switch (verdict) {
      case 'correct':
        return Icons.check_circle;
      case 'mostly_correct':
        return Icons.check_circle_outline;
      case 'needs_revision':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }
}
