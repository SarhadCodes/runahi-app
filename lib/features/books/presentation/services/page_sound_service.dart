import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/library_book.dart';

/// Low-latency paper SFX via [audioplayers] so Quran can own just_audio_background.
class PageSoundService {
  PageSoundService();

  final List<AudioPlayer> _players = [];
  int _next = 0;
  bool _ready = false;
  DateTime? _lastPlay;

  Future<AudioPlayer> _buildPlayer() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setSource(AssetSource('sound/paper_book.mp3'));
    await player.setVolume(0.6);
    return player;
  }

  Future<void> warmUp() async {
    if (_ready && _players.length >= 2) return;
    try {
      for (final p in _players) {
        try {
          await p.dispose();
        } catch (_) {}
      }
      _players
        ..clear()
        ..add(await _buildPlayer())
        ..add(await _buildPlayer());
      _ready = true;
    } catch (e, st) {
      debugPrint('page sound warmUp failed: $e\n$st');
      _ready = false;
    }
  }

  Future<void> play({
    required bool enabled,
    double intensity = 1,
    Duration? flipDuration,
  }) async {
    if (!enabled) return;
    final now = DateTime.now();
    if (_lastPlay != null && now.difference(_lastPlay!) < const Duration(milliseconds: 140)) {
      return;
    }
    _lastPlay = now;

    if (!_ready || _players.length < 2) {
      await warmUp();
    }
    if (!_ready || _players.length < 2) return;

    final player = _players[_next];
    _next = 1 - _next;
    final volume = (0.45 + 0.25 * intensity.clamp(0.5, 1.4)).clamp(0.45, 0.8);

    try {
      unawaited(player.setVolume(volume));
      unawaited(player.seek(Duration.zero));
      unawaited(player.resume());
    } catch (e, st) {
      debugPrint('page sound play failed: $e\n$st');
    }
  }

  Future<void> cancel() async {
    for (final player in _players) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final player in _players) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
    _ready = false;
  }
}

class PdfDocumentService {
  String resolveUrl(LibraryBook book) => book.pdfUrl.trim();
}
