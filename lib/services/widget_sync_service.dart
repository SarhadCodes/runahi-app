import 'package:home_widget/home_widget.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_language.dart';
import '../data/models/core_models.dart';

class WidgetSyncService {
  static const _groupId = 'group.com.rounahi.rounahi';

  Future<void> initialize() {
    return HomeWidget.setAppGroupId(_groupId);
  }

  Future<void> syncDaily({
    required DailyContent daily,
    required AppLanguage language,
    String? latestTitle,
    String? latestKind,
  }) async {
    final translation = daily.translation.resolve(language);
    final topic = daily.topicTitle.resolve(language);
    final message = daily.message.resolve(language);
    await HomeWidget.saveWidgetData<String>('language', language.code);
    await HomeWidget.saveWidgetData<String>('ayah_arabic', daily.arabic);
    await HomeWidget.saveWidgetData<String>('ayah_translation', translation);
    await HomeWidget.saveWidgetData<String>('ayah_id', daily.verseId);
    await HomeWidget.saveWidgetData<String>('word_id', daily.wordId);
    await HomeWidget.saveWidgetData<String>('topic_id', daily.topicId);
    await HomeWidget.saveWidgetData<String>('topic_title', topic);
    await HomeWidget.saveWidgetData<String>('daily_message', message);
    await HomeWidget.saveWidgetData<String>('latest_title', latestTitle ?? topic);
    await HomeWidget.saveWidgetData<String>('latest_kind', latestKind ?? 'topics');
    await HomeWidget.saveWidgetData<String>('brand', AppConstants.appName);
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    await HomeWidget.updateWidget(
      name: AppConstants.widgetAyah,
      androidName: AppConstants.widgetAyah,
      iOSName: 'TodayAyahWidget',
      qualifiedAndroidName: 'com.rounahi.rounahi.${AppConstants.widgetAyah}',
    );
    await HomeWidget.updateWidget(
      name: AppConstants.widgetWord,
      androidName: AppConstants.widgetWord,
      iOSName: 'WordOfDayWidget',
      qualifiedAndroidName: 'com.rounahi.rounahi.${AppConstants.widgetWord}',
    );
    await HomeWidget.updateWidget(
      name: AppConstants.widgetTopic,
      androidName: AppConstants.widgetTopic,
      iOSName: 'TopicOfDayWidget',
      qualifiedAndroidName: 'com.rounahi.rounahi.${AppConstants.widgetTopic}',
    );
    await HomeWidget.updateWidget(
      name: AppConstants.widgetLatest,
      androidName: AppConstants.widgetLatest,
      iOSName: 'LatestContentWidget',
      qualifiedAndroidName: 'com.rounahi.rounahi.${AppConstants.widgetLatest}',
    );
    await HomeWidget.updateWidget(
      name: AppConstants.widgetCompact,
      androidName: AppConstants.widgetCompact,
      iOSName: 'CompactRounahiWidget',
      qualifiedAndroidName: 'com.rounahi.rounahi.${AppConstants.widgetCompact}',
    );
  }
}
