import '../config/build_config.dart';
import '../models/learning.dart';
import '../models/opening_experience.dart';
import 'storage_service.dart';

class OpeningExperienceService {
  OpeningExperienceService(this._storage);

  final StorageService _storage;

  Future<OpeningCardData?> getOpeningCard({
    required LearningPreferences preferences,
    required UserStats stats,
    required bool localModelEnabled,
    required bool localModelLoaded,
    required bool hasApiKey,
  }) async {
    final history = _storage.getOpeningHistory();
    final recentlyShownIds = history
        .take(5)
        .map((item) => item['id'] as String)
        .toSet();

    final primaryTopic = preferences.topics.isNotEmpty
        ? preferences.topics.first
        : LearningTopic.daily;

    final candidates = <OpeningCardData>[
      if (BuildConfig.requiresApiKey && !hasApiKey)
        const OpeningCardData(
          id: 'api_setup',
          title: '连接 DeepSeek，开始今天的练习',
          body: 'Web 版本默认使用 DeepSeek API。先配置密钥，才能生成新的练习题。',
          ctaLabel: '去设置 API',
          actionRoute: '/api-setup',
          tone: 'warning',
        ),
      if (!BuildConfig.requiresApiKey && !localModelLoaded)
        const OpeningCardData(
          id: 'local_model_not_ready',
          title: '本地模型正在准备中',
          body: 'Windows 和 Android 默认使用本地模型。先到设置里完成模型加载，然后就能离线练习。',
          ctaLabel: '打开设置',
          actionRoute: '/settings',
          tone: 'warning',
        ),
      if (!BuildConfig.requiresApiKey && localModelEnabled && localModelLoaded)
        OpeningCardData(
          id: 'local_model_ready',
          title: '你的本地英语教练已经就绪',
          body: '当前设备会默认使用本地模型生成练习。现在可以直接开始，不需要先配 API。',
          ctaLabel: '开始今天的练习',
          actionRoute: '/session',
          actionExtra: {
            'topic': primaryTopic.name,
            'level': preferences.levelLabel,
          },
          tone: 'success',
        ),
      if (stats.currentStreak >= 3)
        OpeningCardData(
          id: 'streak_push',
          title: '你已经连续学习 ${stats.currentStreak} 天',
          body: '今天保持一下节奏就好。我帮你从 ${_topicLabel(primaryTopic)} 这个主题继续。',
          ctaLabel: '继续练习',
          actionRoute: '/session',
          actionExtra: {
            'topic': primaryTopic.name,
            'level': preferences.levelLabel,
          },
          tone: 'celebration',
        ),
      if (stats.todayCount == 0)
        OpeningCardData(
          id: 'first_session_today',
          title: '今天的第一轮练习，从简单开始',
          body: '先来一道和 ${_topicLabel(primaryTopic)} 相关的日常表达题，把今天的状态拉起来。',
          ctaLabel: '开始练习',
          actionRoute: '/session',
          actionExtra: {
            'topic': primaryTopic.name,
            'level': preferences.levelLabel,
          },
        ),
      if (stats.questionsAnswered >= 5)
        const OpeningCardData(
          id: 'review_focus',
          title: '先复习，再冲新题',
          body: '你已经积累了一些练习记录，先看一眼复习队列，会更容易把表达真正记住。',
          ctaLabel: '去复习',
          actionRoute: '/review',
          tone: 'supportive',
        ),
      OpeningCardData(
        id: 'topic_nudge_${primaryTopic.name}',
        title: '把 ${_topicLabel(primaryTopic)} 练熟一点',
        body: '这是你当前偏好的主题。继续围绕它练习，最容易形成可重复输出。',
        ctaLabel: '继续这个主题',
        actionRoute: '/session',
        actionExtra: {
          'topic': primaryTopic.name,
          'level': preferences.levelLabel,
        },
      ),
    ];

    final selected = _selectCandidate(candidates, recentlyShownIds);
    if (selected == null) {
      return null;
    }

    await _storage.recordOpeningExposure(selected);
    return selected;
  }

  OpeningCardData? _selectCandidate(
    List<OpeningCardData> candidates,
    Set<String> recentlyShownIds,
  ) {
    for (final candidate in candidates) {
      if (!recentlyShownIds.contains(candidate.id)) {
        return candidate;
      }
    }
    return candidates.isNotEmpty ? candidates.first : null;
  }

  static String _topicLabel(LearningTopic topic) {
    switch (topic) {
      case LearningTopic.travel:
        return '旅行';
      case LearningTopic.work:
        return '工作';
      case LearningTopic.socialLife:
        return '社交';
      case LearningTopic.shopping:
        return '购物';
      case LearningTopic.dining:
        return '餐饮';
      case LearningTopic.daily:
        return '日常';
    }
  }
}
