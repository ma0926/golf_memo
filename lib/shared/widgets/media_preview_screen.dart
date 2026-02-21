import 'dart:io';
import 'package:flutter/material.dart';

class MediaPreviewScreen extends StatelessWidget {
  final File? file;
  final bool isVideo;

  const MediaPreviewScreen({super.key, this.file, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // コンテンツ
            Center(child: _buildContent()),
            // 閉じるボタン
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
    if (file == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideo ? Icons.videocam : Icons.image,
            size: 80,
            color: Colors.white30,
          ),
        ],
      );
    }

    if (isVideo) {
      // 動画：サムネイル＋再生アイコン（再生機能は今後実装）
      return Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            child: Image.file(file!, fit: BoxFit.contain),
          ),
          const Icon(Icons.play_circle_outline, size: 72, color: Colors.white70),
        ],
      );
    }

    // 画像：ピンチでズーム可能
    return InteractiveViewer(
      child: Image.file(file!, fit: BoxFit.contain),
    );
  }
}
