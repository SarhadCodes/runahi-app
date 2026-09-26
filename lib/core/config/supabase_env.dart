import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEnv {
  SupabaseEnv._();

  static const dartUrl = String.fromEnvironment('SUPABASE_URL');
  static const dartPublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const dartAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String url = dartUrl;
  static String publishableKey = dartPublishableKey.isNotEmpty ? dartPublishableKey : dartAnonKey;
  static bool initialized = false;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static Future<void> load() async {
    if (isConfigured) return;
    try {
      final raw = await rootBundle.loadString('assets/config/supabase.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      url = (json['url'] as String? ?? '').trim();
      publishableKey = (
        json['publishableKey'] as String? ??
        json['anonKey'] as String? ??
        json['anon_key'] as String? ??
        ''
      ).trim();
    } catch (_) {
      // Optional overlay; Imani Kurd remains the fallback.
    }
  }

  static Future<void> initialize() async {
    await load();
    if (!isConfigured || initialized) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    initialized = true;
  }
}
