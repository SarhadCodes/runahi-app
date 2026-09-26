import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentSyncProvider).pull();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final feed = ref.watch(notificationFeedProvider);
    return CatalogPageScaffold(
      title: strings.navNotifications,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: feed.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
        data: (items) {
          final filtered = items.where((item) {
            final text = '${strings.newContentLabel(item.kind.name)} ${item.body.resolve(language)}';
            return text.contains(_query);
          }).toList();
          if (filtered.isEmpty) {
            return StatusPanel(title: strings.emptyTitle, body: strings.emptyBody);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final when = DateFormat('yyyy/MM/dd  HH:mm').format(item.createdAt.toLocal());
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ref.read(inboxProvider.notifier).markRead(item);
                    context.push(item.deepLink);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.read ? AppColors.white : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.read
                            ? AppColors.border
                            : AppColors.navy.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CatalogIconBadge(
                                icon: item.read
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_rounded,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.body.resolve(language),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F6),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          ),
                          child: Text(
                            '${strings.newContentLabel(item.kind.name)} · $when',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
