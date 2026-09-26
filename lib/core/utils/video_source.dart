class VideoSource {
  const VideoSource._();

  static final _idPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  static final _directPattern = RegExp(r'\.(mp4|m3u8|webm|mov|m4v)(\?.*)?$', caseSensitive: false);

  static String? youtubeId(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    if (_idPattern.hasMatch(value)) return value;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m|music)\.'), '');
    final isYoutube = host == 'youtu.be' ||
        host == 'youtube.com' ||
        host == 'youtube-nocookie.com' ||
        host.endsWith('.youtube.com') ||
        host.endsWith('.youtube-nocookie.com');
    if (!isYoutube) return null;

    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null && _idPattern.hasMatch(fromQuery)) return fromQuery;

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (host == 'youtu.be' && _idPattern.hasMatch(segments.first)) return segments.first;

    const prefixes = {'embed', 'shorts', 'live', 'v', 'watch', 'e'};
    if (segments.length >= 2 && prefixes.contains(segments.first) && _idPattern.hasMatch(segments[1])) {
      return segments[1];
    }
    return null;
  }

  static double? startSeconds(String? raw) {
    final uri = Uri.tryParse(raw?.trim() ?? '');
    if (uri == null) return null;
    final token = uri.queryParameters['start'] ?? uri.queryParameters['t'];
    if (token == null || token.isEmpty) return null;
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(token)) return double.tryParse(token);
    final match = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$').firstMatch(token);
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
    final total = hours * 3600 + minutes * 60 + seconds;
    return total == 0 ? null : total.toDouble();
  }

  static bool isDirectVideo(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || youtubeId(value) != null) return false;
    return _directPattern.hasMatch(value);
  }

  static String? thumbnailUrl(String? videoUrl, {String? fallback}) {
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    final id = youtubeId(videoUrl);
    if (id == null) return null;
    return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  }
}
