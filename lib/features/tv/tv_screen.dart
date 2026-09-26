import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import 'data/tv_channel.dart';
import 'tv_providers.dart';

bool get _useBetterPlayer {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class TvScreen extends ConsumerStatefulWidget {
  const TvScreen({super.key});

  @override
  ConsumerState<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends ConsumerState<TvScreen> {
  BetterPlayerController? _betterController;
  VideoPlayerController? _webController;
  Object? _error;
  bool _loading = true;
  TvChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupPlayer());
  }

  Future<void> _setupPlayer() async {
    _betterController?.removeEventsListener(_onPlayerEvent);
    _betterController?.dispose(forceDispose: true);
    await _webController?.dispose();

    setState(() {
      _error = null;
      _loading = true;
      _betterController = null;
      _webController = null;
    });

    try {
      ref.invalidate(primaryTvChannelProvider);
      final channel = await ref.read(primaryTvChannelProvider.future);
      if (!mounted) return;
      if (channel == null || !channel.hasStream) {
        setState(() {
          _channel = channel;
          _error = 'missing-stream';
          _loading = false;
        });
        return;
      }
      setState(() => _channel = channel);
      final streamUrl = channel.streamUrl.trim();
      if (_useBetterPlayer) {
        _setupBetterPlayer(streamUrl);
        return;
      }
      await _setupWebPlayer(streamUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _setupBetterPlayer(String streamUrl) {
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamUrl,
      liveStream: true,
      videoFormat: BetterPlayerVideoFormat.hls,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 2000,
        maxBufferMs: 15000,
        bufferForPlaybackMs: 1000,
        bufferForPlaybackAfterRebufferMs: 2000,
      ),
    );

    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        handleLifecycle: true,
        autoDetectFullscreenDeviceOrientation: true,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableSkips: false,
          enableProgressBar: false,
          enableProgressText: false,
          enablePlaybackSpeed: false,
          enableSubtitles: false,
          enableQualities: false,
          enableOverflowMenu: false,
          enableFullscreen: true,
          showControlsOnInitialize: false,
          controlBarColor: Colors.transparent,
          loadingColor: AppColors.goldSoft,
          iconsColor: AppColors.white,
          liveTextColor: Color(0xFFE53935),
        ),
        placeholder: const ColoredBox(
          color: AppColors.deepNavy,
          child: Center(child: CircularProgressIndicator(color: AppColors.goldSoft)),
        ),
        errorBuilder: (context, errorMessage) {
          final strings = ref.read(stringsProvider);
          return _TvErrorPane(
            message: strings.tvUnavailable,
            detail: errorMessage,
            onRetry: _setupPlayer,
            retryLabel: strings.retry,
          );
        },
      ),
      betterPlayerDataSource: dataSource,
    );

    controller.addEventsListener(_onPlayerEvent);
    if (!mounted) {
      controller.dispose(forceDispose: true);
      return;
    }
    setState(() {
      _betterController = controller;
      _loading = false;
    });
  }

  Future<void> _setupWebPlayer(String streamUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _webController = controller;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      setState(() => _error = event.parameters?['exception'] ?? 'error');
    }
  }

  void _enterFullscreen() {
    _betterController?.enterFullScreen();
  }

  @override
  void dispose() {
    _betterController?.removeEventsListener(_onPlayerEvent);
    _betterController?.dispose(forceDispose: true);
    _webController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final resolved = _channel?.name.resolve(language).trim() ?? '';
    final channelName = resolved.isNotEmpty ? resolved : strings.tvChannelName;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.tvBackground,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFFF7F1E6)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _TvBackButton(onTap: () => Navigator.of(context).maybePop()),
                      ),
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.018),
                      _TvTitleBlock(
                        title: strings.tvTitle,
                      ),
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.04),
                      _TvChannelCard(
                        channelName: channelName,
                        liveLabel: strings.tvLive,
                      ),
                      const SizedBox(height: 16),
                      _TvPlayerFrame(
                        onFullscreen: _betterController != null ? _enterFullscreen : null,
                        showLiveBadge: !_loading && _error == null,
                        liveLabel: strings.tvLive,
                        child: _buildPlayerSurface(strings),
                      ),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSurface(AppStrings strings) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.goldSoft));
    }
    if (_betterController != null) {
      return BetterPlayer(controller: _betterController!);
    }
    final web = _webController;
    if (web != null && web.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            web.value.isPlaying ? web.pause() : web.play();
          });
        },
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: web.value.size.width,
            height: web.value.size.height,
            child: VideoPlayer(web),
          ),
        ),
      );
    }
    return _TvErrorPane(
      message: strings.tvUnavailable,
      detail: kIsWeb ? strings.tvWebHint : _error?.toString(),
      onRetry: _setupPlayer,
      retryLabel: strings.retry,
    );
  }
}

class _TvBackButton extends StatelessWidget {
  const _TvBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldSoft.withValues(alpha: 0.7), width: 1.2),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 18),
        ),
      ),
    );
  }
}

class _TvTitleBlock extends StatelessWidget {
  const _TvTitleBlock({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTypography.uiFamily,
          color: AppColors.white,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
          shadows: [
            Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}

class _TvChannelCard extends StatelessWidget {
  const _TvChannelCard({
    required this.channelName,
    required this.liveLabel,
  });

  final String channelName;
  final String liveLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cell_tower_rounded, color: AppColors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  liveLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: AppTypography.uiFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              channelName,
              style: const TextStyle(
                fontFamily: AppTypography.uiFamily,
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.tv_rounded, color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}

class _TvPlayerFrame extends StatelessWidget {
  const _TvPlayerFrame({
    required this.child,
    required this.showLiveBadge,
    required this.liveLabel,
    this.onFullscreen,
  });

  final Widget child;
  final bool showLiveBadge;
  final String liveLabel;
  final VoidCallback? onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.deepNavy),
              Positioned(
                top: 8,
                left: 10,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold.withValues(alpha: 0.55),
                  size: 16,
                ),
              ),
              child,
              if (showLiveBadge)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 7, color: AppColors.white),
                        const SizedBox(width: 5),
                        Text(
                          liveLabel,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (onFullscreen != null)
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: IconButton(
                    onPressed: onFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded, color: AppColors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvErrorPane extends StatelessWidget {
  const _TvErrorPane({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.detail,
  });

  final String message;
  final String? detail;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    // Keep the in-player error compact — long ExoPlayer dumps overflow the video box.
    return Material(
      color: AppColors.deepNavy,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: AppColors.goldSoft),
                child: Text(retryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
