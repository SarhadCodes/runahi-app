import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/core_models.dart';
import '../localization/app_language.dart';

class WhatsAppLauncher {
  const WhatsAppLauncher();

  Future<bool> open(AppConfig config, AppLanguage language) async {
    final number = config.whatsAppNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (number.isEmpty) return false;
    final text = Uri.encodeComponent(config.whatsAppPrefill.resolve(language));
    final uri = Uri.parse('https://wa.me/$number?text=$text');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String arabicDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return '$value'.split('').map((ch) {
    final index = western.indexOf(ch);
    return index == -1 ? ch : eastern[index];
  }).join();
}

class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 280)});

  final Duration delay;
  VoidCallback? _pending;

  void run(VoidCallback callback) {
    _pending = callback;
    Future<void>.delayed(delay, () {
      if (_pending == callback) {
        callback();
        _pending = null;
      }
    });
  }

  void dispose() => _pending = null;
}
