import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/local/local_store.dart';
import '../../data/providers.dart';

import '../../features/about/about_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/books/book_detail_screen.dart';
import '../../features/books/book_reader_screen.dart';
import '../../features/books/books_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/questions/question_detail_screen.dart';
import '../../features/questions/questions_screen.dart';
import '../../features/research/research_detail_screen.dart';
import '../../features/research/research_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/topics/topic_detail_screen.dart';
import '../../features/topics/topics_screen.dart';
import '../../features/verse_meaning/verse_detail_screen.dart';
import '../../features/verse_meaning/verses_screen.dart';
import '../../features/videos/video_detail_screen.dart';
import '../../features/videos/videos_screen.dart';
import '../../features/tv/tv_screen.dart';
import '../../features/word_meaning/word_detail_screen.dart';
import '../../features/word_meaning/words_screen.dart';
import '../../features/qibla/qibla_screen.dart';
import '../../features/quran_listen/quran_ayah_picker_screen.dart';
import '../../features/quran_listen/quran_player_screen.dart';
import '../../features/quran_listen/quran_surahs_screen.dart';
import 'app_routes.dart';

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondary, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(fade),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final store = ref.watch(localStoreProvider);
  final router = _createRouter(store);
  ref.onDispose(router.dispose);
  return router;
});

GoRouter _createRouter(LocalStore store) {
  return GoRouter(
  initialLocation: AppRoutes.splash,
  restorationScopeId: 'rounahi',
  redirect: (context, state) {
    final done = store.onboardingComplete();
    final location = state.matchedLocation;
    final onOnboarding = location == AppRoutes.onboarding;
    final onSplash = location == AppRoutes.splash;
    if (!done && !onOnboarding && !onSplash) {
      return AppRoutes.onboarding;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _fade(const SplashScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _fade(const OnboardingScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _fade(const HomeScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.books,
      pageBuilder: (context, state) => _fade(const BooksScreen(), state),
    ),
    GoRoute(
      path: '/books/:id',
      pageBuilder: (context, state) => _fade(BookDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: '/books/:id/read',
      pageBuilder: (context, state) => _fade(
        BookReaderScreen(id: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: AppRoutes.research,
      pageBuilder: (context, state) => _fade(const ResearchScreen(), state),
    ),
    GoRoute(
      path: '/research/:id',
      pageBuilder: (context, state) => _fade(ResearchDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: AppRoutes.verses,
      pageBuilder: (context, state) => _fade(const VersesScreen(), state),
    ),
    GoRoute(
      path: '/verses/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        if (id.contains('-') || id.contains(':')) {
          return _fade(VerseDetailScreen(id: id.replaceAll(':', '-')), state);
        }
        return _fade(SurahTafsirScreen(surahNumber: int.tryParse(id) ?? 1), state);
      },
    ),
    GoRoute(
      path: AppRoutes.words,
      pageBuilder: (context, state) => _fade(const WordsScreen(), state),
    ),
    GoRoute(
      path: '/words/:id',
      pageBuilder: (context, state) => _fade(WordDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: AppRoutes.videos,
      pageBuilder: (context, state) => _fade(const VideosScreen(), state),
    ),
    GoRoute(
      path: '/videos/:id',
      pageBuilder: (context, state) => _fade(VideoDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: AppRoutes.tv,
      pageBuilder: (context, state) => _fade(const TvScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.questions,
      pageBuilder: (context, state) => _fade(const QuestionsScreen(), state),
    ),
    GoRoute(
      path: '/questions/:id',
      pageBuilder: (context, state) => _fade(QuestionDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: AppRoutes.topics,
      pageBuilder: (context, state) => _fade(const TopicsScreen(), state),
    ),
    GoRoute(
      path: '/topics/:id',
      pageBuilder: (context, state) => _fade(TopicDetailScreen(id: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: AppRoutes.bookmarks,
      pageBuilder: (context, state) => _fade(const BookmarksScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.about,
      pageBuilder: (context, state) => _fade(const AboutScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (context, state) => _fade(SearchScreen(initial: state.uri.queryParameters['q']), state),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => _fade(const SettingsScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => _fade(const NotificationsScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.quran,
      pageBuilder: (context, state) => _fade(const QuranSurahsScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.qibla,
      pageBuilder: (context, state) => _fade(const QiblaScreen(), state),
    ),
    GoRoute(
      path: '/quran/:surah/play',
      pageBuilder: (context, state) {
        final surah = int.tryParse(state.pathParameters['surah'] ?? '') ?? 1;
        final reciter = state.uri.queryParameters['reciter'] ?? 'ar.alafasy';
        final ayahs = (state.uri.queryParameters['ayahs'] ?? '')
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toList();
        return _fade(
          QuranPlayerScreen(
            surahNumber: surah,
            reciterId: reciter,
            fromAyah: int.tryParse(state.uri.queryParameters['from'] ?? '1') ?? 1,
            toAyah: int.tryParse(state.uri.queryParameters['to'] ?? ''),
            ayahNumbers: ayahs,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/quran/:surah',
      pageBuilder: (context, state) {
        final surah = int.tryParse(state.pathParameters['surah'] ?? '') ?? 1;
        final reciter = state.uri.queryParameters['reciter'] ?? 'ar.alafasy';
        return _fade(QuranAyahPickerScreen(surahNumber: surah, reciterId: reciter), state);
      },
    ),
    GoRoute(
      path: AppRoutes.privacy,
      pageBuilder: (context, state) => _fade(const LegalScreen(kind: LegalKind.privacy), state),
    ),
    GoRoute(
      path: AppRoutes.terms,
      pageBuilder: (context, state) => _fade(const LegalScreen(kind: LegalKind.terms), state),
    ),
  ],
  );
}
