import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewScreen extends StatefulWidget {
  final File? file;       // 画像ファイル、または動画のサムネイル画像
  final bool isVideo;
  final String? videoPath; // 動画の実ファイルパス（再生に使用）

  const MediaPreviewScreen({
    super.key,
    this.file,
    this.isVideo = false,
    this.videoPath,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.videoPath != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.file(File(widget.videoPath!));
      _controller = controller;
      await controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        controller.play();
      }
    } catch (_) {
      // 読み込み失敗時はサムネイル表示にフォールバック
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _buildContent()),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!widget.isVideo) {
      if (widget.file == null) {
        return const Icon(Icons.image, size: 80, color: Colors.white30);
      }
      return InteractiveViewer(
        child: Image.file(widget.file!, fit: BoxFit.contain),
      );
    }

    // 動画：初期化完了 → VideoPlayer を表示
    if (_initialized && _controller != null) {
      return _buildVideoPlayer();
    }

    // 動画：初期化中 or videoPath未指定 → サムネイル表示
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.file != null)
          InteractiveViewer(
            child: Image.file(widget.file!, fit: BoxFit.contain),
          ),
        // videoPathがある場合はローディング、ない場合は再生アイコン
        if (widget.videoPath != null)
          const CircularProgressIndicator(color: Colors.white)
        else
          const Icon(Icons.play_circle_outline, size: 72, color: Colors.white70),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          // 一時停止中のみ再生アイコンを表示
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (context, value, child) {
              return AnimatedOpacity(
                opacity: value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 72,
                  color: Colors.white70,
                ),
              );
            },
          ),
          // 進捗バー（スクラブ可能）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
