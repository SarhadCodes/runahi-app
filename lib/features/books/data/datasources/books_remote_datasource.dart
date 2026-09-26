import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_env.dart';
import '../../../../data/models/core_models.dart';
import '../models/library_book.dart';

class BooksRemoteDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  bool get ready => SupabaseEnv.initialized;

  LocalizedText _cols(Map<String, dynamic> json, String key) {
    final sorani = '${json['${key}_sorani'] ?? ''}';
    var badini = '${json['${key}_badini'] ?? ''}';
    if (badini.isEmpty) badini = sorani;
    if (sorani.isEmpty && badini.isEmpty) return LocalizedText.empty;
    return LocalizedText(sorani: sorani.isEmpty ? badini : sorani, badini: badini);
  }

  String _pdfUrl(Map<String, dynamic> json) {
    final candidates = [
      json['pdf_url'],
      json['source_url'],
      json['pdf'],
      json['file_url'],
    ];
    for (final value in candidates) {
      final url = '$value'.trim();
      if (url.isNotEmpty && url != 'null') return url;
    }
    return '';
  }

  LibraryBook _book(Map<String, dynamic> json, {Map<String, BookCategory>? categories}) {
    final categoryId = json['category_id'] as String?;
    return LibraryBook(
      id: json['id'] as String,
      title: _cols(json, 'title'),
      author: _cols(json, 'author'),
      description: _cols(json, 'description'),
      coverImageUrl: (json['cover_image_url'] ?? json['cover_url']) as String?,
      pdfUrl: _pdfUrl(json),
      categoryId: categoryId,
      categoryTitle: categoryId == null
          ? _cols(json, 'category')
          : categories?[categoryId]?.title ?? _cols(json, 'category'),
      language: '${json['language'] ?? 'ku'}',
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      featured: json['featured'] == true,
    );
  }

  BookCategory _category(Map<String, dynamic> json) {
    return BookCategory(
      id: json['id'] as String,
      title: _cols(json, 'title'),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<BookCategory>> fetchCategories() async {
    if (!ready) return const [];
    try {
      final rows = await _client.from('book_categories').select().order('sort_order');
      return [
        for (final row in rows as List<dynamic>)
          if (row is Map<String, dynamic>) _category(row),
      ];
    } catch (e, st) {
      debugPrint('book_categories fetch failed: $e\n$st');
      return const [];
    }
  }

  Future<List<LibraryBook>> fetchBooks() async {
    if (!ready) return const [];
    try {
      final categories = {
        for (final item in await fetchCategories()) item.id: item,
      };
      // Prefer updated_at — always present on production books schema.
      // Do not require published_at / pdf_url columns from the new migration.
      List<dynamic> rows;
      try {
        rows = await _client.from('books').select().order('updated_at', ascending: false);
      } catch (_) {
        rows = await _client.from('books').select();
      }
      final books = [
        for (final row in rows)
          if (row is Map<String, dynamic>) _book(row, categories: categories),
      ];
      // Show books that have a PDF URL; if none do, still show all so the catalog isn't empty.
      final withPdf = books.where((book) => book.hasPdf).toList();
      return withPdf.isNotEmpty ? withPdf : books;
    } catch (e, st) {
      debugPrint('books fetch failed: $e\n$st');
      return const [];
    }
  }

  Future<LibraryBook?> fetchBook(String id) async {
    if (!ready) return null;
    try {
      final row = await _client.from('books').select().eq('id', id).maybeSingle();
      if (row is Map<String, dynamic>) {
        final categories = {
          for (final item in await fetchCategories()) item.id: item,
        };
        return _book(row, categories: categories);
      }
    } catch (e, st) {
      debugPrint('book fetch failed: $e\n$st');
    }
    final books = await fetchBooks();
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }
}
