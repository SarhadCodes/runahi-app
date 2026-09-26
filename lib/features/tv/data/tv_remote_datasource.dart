import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env.dart';
import '../../../data/models/core_models.dart';
import 'tv_channel.dart';

class TvRemoteDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  bool get ready => SupabaseEnv.initialized;

  LocalizedText _cols(Map<String, dynamic> json, String key) {
    final sorani = '${json['${key}_sorani'] ?? ''}';
    var badini = '${json['${key}_badini'] ?? ''}';
    if (badini.isEmpty) badini = sorani;
    if (sorani.isEmpty && badini.isEmpty) return LocalizedText.empty;
    return LocalizedText(sorani: sorani.isEmpty ? badini : sorani, badini: badini);
  }

  TvChannel _map(Map<String, dynamic> json) {
    return TvChannel(
      id: json['id'] as String,
      name: _cols(json, 'name'),
      streamUrl: '${json['stream_url'] ?? ''}'.trim(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<TvChannel>> fetchChannels() async {
    if (!ready) return const [];
    try {
      final rows = await _client
          .from('tv_channels')
          .select()
          .eq('enabled', true)
          .order('sort_order');
      return [
        for (final row in rows as List<dynamic>)
          if (row is Map<String, dynamic>) _map(row),
      ].where((c) => c.hasStream).toList();
    } catch (e, st) {
      debugPrint('tv_channels fetch failed: $e\n$st');
      return const [];
    }
  }

  Future<TvChannel?> fetchPrimaryChannel() async {
    final channels = await fetchChannels();
    if (channels.isEmpty) return null;
    return channels.first;
  }
}
