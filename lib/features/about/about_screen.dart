import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final config = ref.watch(configProvider);

    return CatalogPageScaffold(
      title: strings.aboutTitle,
      child: config.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(configProvider),
        ),
        data: (data) {
          final about = data.aboutBody.resolve(language).trim();
          final mission = data.missionBody.resolve(language).trim();
          final team = data.teamBody.resolve(language).trim();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const RounahiLogo(size: 140, borderRadius: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  color: AppColors.navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: AppTypography.uiFamily,
                      height: 1.5,
                    ),
              ),
              if (about.isNotEmpty) ...[
                const SizedBox(height: 22),
                _Section(title: strings.whatIsRounahi, body: about),
              ],
              if (mission.isNotEmpty) ...[
                const SizedBox(height: 18),
                _Section(title: strings.mission, body: mission),
              ],
              if (team.isNotEmpty) ...[
                const SizedBox(height: 18),
                _Section(title: strings.team, body: team),
              ],
              const SizedBox(height: 22),
              CatalogListCard(
                title: strings.contactWhatsApp,
                footer: strings.contactViaWhatsApp,
                leading: const WhatsAppIconBadge(),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.navy.withValues(alpha: 0.35)),
                onTap: () async {
                  final ok = await const WhatsAppLauncher().open(data, language);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.whatsAppUnavailable)),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              CatalogListCard(
                title: strings.privacyPolicy,
                leading: const CatalogIconBadge(icon: Icons.shield_outlined),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.navy.withValues(alpha: 0.35)),
                onTap: () => context.push('/privacy'),
              ),
              const SizedBox(height: 12),
              CatalogListCard(
                title: strings.terms,
                leading: const CatalogIconBadge(icon: Icons.description_outlined),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.navy.withValues(alpha: 0.35)),
                onTap: () => context.push('/terms'),
              ),
              const SizedBox(height: 12),
              CatalogListCard(
                title: '${strings.version} ${AppConstants.version}',
                footer: strings.developedBy,
                leading: const CatalogIconBadge(icon: Icons.info_outline_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.navy,
                fontFamily: AppTypography.uiFamily,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ScriptAwareText(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.85,
                    fontFamily: AppTypography.uiFamily,
                    color: AppColors.navy,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

enum LegalKind { privacy, terms }

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.kind});
  final LegalKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final title = kind == LegalKind.privacy ? strings.privacyPolicy : strings.terms;
    final body = kind == LegalKind.privacy ? strings.privacyPolicyBody : strings.termsBody;
    return CatalogPageScaffold(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.85,
                      fontFamily: AppTypography.uiFamily,
                    ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
