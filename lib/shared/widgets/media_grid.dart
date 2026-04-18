import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/media_path_helper.dart';
import '../../data/models/media.dart';
import 'media_preview_screen.dart';

/// メディアアイテムの表示情報
typedef MemoMediaItem = ({String displayPath, bool isVideo, String? videoPath});

/// 画像・動画グリッド（最大4件）。
/// [items] には解決済みのパスを渡す。
/// Media オブジェクトから変換する場合は [MediaGrid.fromMedia] を使う。
class MediaGrid extends StatelessWidget {
  final List<MemoMediaItem> items;

  const MediaGrid({super.key, required this.items});

  /// Media リストを MemoMediaItem に変換するヘルパー。
  static List<MemoMediaItem> fromMedia(List<Media> mediaList, String docsPath) {
    return mediaList.take(4).map((m) {
      final thumbPath = m.isVideo && m.thumbnailUri != null
          ? MediaPathHelper.resolve(m.thumbnailUri!, docsPath)
          : null;
      final imagePath = !m.isVideo
          ? MediaPathHelper.resolve(m.uri, docsPath)
          : null;
      final videoPath = m.isVideo
          ? MediaPathHelper.resolve(m.uri, docsPath)
          : null;
      return (
        displayPath: thumbPath ?? imagePath ?? '',
        isVideo: m.isVideo,
        videoPath: videoPath,
      );
    }).toList();
  }

  void _openPreview(BuildContext context, MemoMediaItem item) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => MediaPreviewScreen(
          file: item.displayPath.isNotEmpty ? File(item.displayPath) : null,
          isVideo: item.isVideo,
          videoPath: item.videoPath,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _imgTile(BuildContext context, int index) {
    final item = items[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPreview(context, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.displayPath.isNotEmpty)
            Image.file(
              File(item.displayPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundMiddle),
            )
          else
            Container(
              color: const Color(0xFF2C2C2E),
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white54, size: 32),
              ),
            ),
          if (item.isVideo)
            const Center(
              child: Icon(Icons.play_circle_filled, size: 36, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = items.length.clamp(0, 4);
    if (count == 0) return const SizedBox.shrink();

    Widget grid;
    if (count == 1) {
      grid = _imgTile(context, 0);
    } else if (count == 2) {
      grid = Row(children: [
        Expanded(child: _imgTile(context, 0)),
        const SizedBox(width: 4),
        Expanded(child: _imgTile(context, 1)),
      ]);
    } else if (count == 3) {
      grid = Row(children: [
        Expanded(child: _imgTile(context, 0)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(children: [
            Expanded(child: _imgTile(context, 1)),
            const SizedBox(height: 4),
            Expanded(child: _imgTile(context, 2)),
          ]),
        ),
      ]);
    } else {
      grid = Row(children: [
        Expanded(child: _imgTile(context, 0)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(children: [
            Expanded(child: _imgTile(context, 1)),
            const SizedBox(height: 4),
            Expanded(
              child: Row(children: [
                Expanded(child: _imgTile(context, 2)),
                const SizedBox(width: 4),
                Expanded(child: _imgTile(context, 3)),
              ]),
            ),
          ]),
        ),
      ]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(height: 165, child: grid),
    );
  }
}
