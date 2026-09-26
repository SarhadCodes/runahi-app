import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/video_source.dart';

class RounahiVideoPlayer extends StatelessWidget {
  const RounahiVideoPlayer({
    super.key,
    required this.url,
    this.thumbnailUrl,
    required this.watchOnYoutubeLabel,
    required this.unavailableLabel,
  });

  final String? url;
  final String? thumbnailUrl;
  final String watchOnYoutubeLabel;
  final String unavailableLabel;

  static bool get supportsInlineYoutube {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final youtubeId = VideoSource.youtubeId(url);
    if (youtubeId != null) {
      if (supportsInlineYoutube) {
        return _YoutubeEmbed(
          videoId: youtubeId,
          startSeconds: VideoSource.startSeconds(url),
        );
      }
      return _VideoShell(
        thumbnailUrl: VideoSource.thumbnailUrl(url, fallback: thumbnailUrl),
        child: _PlayOverlay(
          label: watchOnYoutubeLabel,
          onPressed: () => openExternalUrl(url!),
        ),
      );
    }
    if (VideoSource.isDirectVideo(url)) {
      return _DirectVideoEmbed(url: url!);
    }
    if (url != null && url!.trim().isNotEmpty) {
      return _VideoShell(
        thumbnailUrl: VideoSource.thumbnailUrl(url, fallback: thumbnailUrl),
        child: _PlayOverlay(
          label: watchOnYoutubeLabel,
          onPressed: () => openExternalUrl(url!),
        ),
      );
    }
    return _VideoShell(
      thumbnailUrl: thumbnailUrl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            unavailableLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldSoft),
          ),
        ),
      ),
    );
  }
}

class _YoutubeEmbed extends StatefulWidget {
  const _YoutubeEmbed({required this.videoId, this.startSeconds});

  final String videoId;
  final double? startSeconds;

  @override
  State<_YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<_YoutubeEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      startSeconds: widget.startSeconds,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        strictRelatedVideos: true,
        color: 'red',
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.deepNavy,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
}

class _DirectVideoEmbed extends StatefulWidget {
  const _DirectVideoEmbed({required this.url});
  final String url;

  @override
  State<_DirectVideoEmbed> createState() => _DirectVideoEmbedState();
}

class _DirectVideoEmbedState extends State<_DirectVideoEmbed> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.deepNavy,
        child: AspectRatio(
          aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9,
          child: _failed
              ? _PlayOverlay(label: widget.url, onPressed: () => openExternalUrl(widget.url))
              : !_ready
                  ? const Center(child: CircularProgressIndicator(color: AppColors.goldSoft))
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            const Icon(Icons.play_circle_fill_rounded, color: AppColors.goldSoft, size: 64),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _VideoShell extends StatelessWidget {
  const _VideoShell({required this.child, this.thumbnailUrl});

  final Widget child;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.navy,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                Image.network(
                  thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: AppColors.goldSoft, size: 64),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}
