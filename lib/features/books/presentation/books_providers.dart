import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../data/datasources/books_remote_datasource.dart';
import '../data/models/library_book.dart';
import 'services/page_sound_service.dart';
import 'services/reading_progress_service.dart';

final booksRemoteDatasourceProvider = Provider<BooksRemoteDatasource>((ref) {
  return BooksRemoteDatasource();
});

final libraryBooksProvider = FutureProvider<List<LibraryBook>>((ref) {
  return ref.watch(booksRemoteDatasourceProvider).fetchBooks();
});

final libraryCategoriesProvider = FutureProvider<List<BookCategory>>((ref) {
  return ref.watch(booksRemoteDatasourceProvider).fetchCategories();
});

final libraryBookProvider = FutureProvider.family<LibraryBook?, String>((ref, id) async {
  final books = await ref.watch(libraryBooksProvider.future);
  for (final book in books) {
    if (book.id == id) return book;
  }
  return ref.watch(booksRemoteDatasourceProvider).fetchBook(id);
});

final readingProgressServiceProvider = Provider<ReadingProgressService>((ref) {
  return ReadingProgressService(ref.watch(localStoreProvider).prefs);
});

final bookBookmarkServiceProvider = Provider<BookBookmarkService>((ref) {
  return BookBookmarkService(ref.watch(localStoreProvider).prefs);
});

final readerPreferencesServiceProvider = Provider<ReaderPreferencesService>((ref) {
  return ReaderPreferencesService(ref.watch(localStoreProvider).prefs);
});

final pageSoundServiceProvider = Provider<PageSoundService>((ref) {
  final service = PageSoundService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

class ReaderPreferencesNotifier extends Notifier<ReaderPreferences> {
  @override
  ReaderPreferences build() {
    return ref.watch(readerPreferencesServiceProvider).load();
  }

  Future<void> update(ReaderPreferences prefs) async {
    state = prefs;
    await ref.read(readerPreferencesServiceProvider).save(prefs);
  }
}

final readerPreferencesProvider =
    NotifierProvider<ReaderPreferencesNotifier, ReaderPreferences>(ReaderPreferencesNotifier.new);

class ReadingProgressNotifier extends Notifier<Map<String, BookReadingProgress>> {
  @override
  Map<String, BookReadingProgress> build() {
    return ref.watch(readingProgressServiceProvider).all();
  }

  Future<void> save(String bookId, int page) async {
    await ref.read(readingProgressServiceProvider).save(bookId, page);
    state = ref.read(readingProgressServiceProvider).all();
  }

  Future<void> reset(String bookId) async {
    await ref.read(readingProgressServiceProvider).reset(bookId);
    state = ref.read(readingProgressServiceProvider).all();
  }
}

final readingProgressMapProvider =
    NotifierProvider<ReadingProgressNotifier, Map<String, BookReadingProgress>>(ReadingProgressNotifier.new);
