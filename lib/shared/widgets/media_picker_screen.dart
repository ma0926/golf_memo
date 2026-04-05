import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// ライブラリから画像・動画を選択するカスタムピッカー。
/// 動画はタップするとプレビュー画面で確認してから選択できる。
///
/// 戻り値: ({List<XFile> images, XFile? video})
/// キャンセル時: null
class MediaPickerScreen extends StatefulWidget {
  /// まだ追加できる画像の枚数
  final int maxImages;

  /// 動画をまだ追加できるか
  final bool videoAllowed;

  const MediaPickerScreen({
    super.key,
    required this.maxImages,
    required this.videoAllowed,
  });

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedImages = [];
  AssetEntity? _selectedVideo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final allAlbum = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );

    final assets = await allAlbum.getAssetListPaged(page: 0, size: 300);

    if (mounted) {
      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    }
  }

  bool _isImageSelected(AssetEntity asset) => _selectedImages.contains(asset);

  int _imageSelectionIndex(AssetEntity asset) => _selectedImages.indexOf(asset);

  void _toggleImage(AssetEntity asset) {
    if (_selectedImages.contains(asset)) {
      setState(() => _selectedImages.remove(asset));
    } else if (_selectedImages.length < widget.maxImages) {
      setState(() => _selectedImages.add(asset));
    }
  }

  Future<void> _previewVideo(AssetEntity asset) async {
    final file = await asset.originFile;
    if (file == null || !mounted) return;

    final result = await Navigator.of(context).push<bool?>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _VideoPreviewPage(
          file: file,
          isSelected: _selectedVideo == asset,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );

    if (result == null || !mounted) return;
    setState(() => _selectedVideo = result ? asset : null);
  }

  Future<void> _confirm() async {
    // AssetEntity → XFile に変換してから返す
    final imageFiles = <XFile>[];
    for (final asset in _selectedImages) {
      final file = await asset.originFile;
      if (file != null) imageFiles.add(XFile(file.path));
    }

    XFile? videoFile;
    if (_selectedVideo != null) {
      final file = await _selectedVideo!.originFile;
      if (file != null) videoFile = XFile(file.path);
    }

    if (mounted) {
      Navigator.of(context).pop((images: imageFiles, video: videoFile));
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _selectedImages.length + (_selectedVideo != null ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ライブラリ',
          style: AppTypography.jpMMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (totalSelected > 0)
            TextButton(
              onPressed: _confirm,
              child: Text(
                '完了($totalSelected)',
                style: AppTypography.jpMMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 64),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _assets.isEmpty
              ? Center(
                  child: Text(
                    '写真・動画がありません',
                    style: AppTypography.jpMRegular.copyWith(color: Colors.white54),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final isVideo = asset.type == AssetType.video;

                    final imageSelected = !isVideo && _isImageSelected(asset);
                    final videoSelected = isVideo && _selectedVideo == asset;
                    final isSelected = imageSelected || videoSelected;

                    // 選択不可かどうか（薄暗く表示）
                    final cannotSelect = !isSelected &&
                        (isVideo
                            ? !widget.videoAllowed && _selectedVideo == null
                            : _selectedImages.length >= widget.maxImages);

                    return GestureDetector(
                      onTap: () {
                        if (isVideo) {
                          _previewVideo(asset);
                        } else if (!cannotSelect) {
                          _toggleImage(asset);
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // サムネイル
                          _AssetThumbnail(asset: asset),
                          // 動画: 再生アイコン＋時間
                          if (isVideo) ...[
                            const Positioned(
                              bottom: 6,
                              left: 6,
                              child: Icon(Icons.play_circle_filled,
                                  color: Colors.white, size: 22),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 6,
                              child: Text(
                                _formatDuration(asset.videoDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                                ),
                              ),
                            ),
                          ],
                          // 選択済みオーバーレイ
                          if (isSelected)
                            Container(color: Colors.black38),
                          // 選択不可オーバーレイ
                          if (cannotSelect)
                            Container(color: Colors.black45),
                          // 選択インジケーター（右上）
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.accent : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: isVideo
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 14)
                                          : Text(
                                              '${_imageSelectionIndex(asset) + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ── 動画プレビューページ ──────────────────────────────
class _VideoPreviewPage extends StatefulWidget {
  final File file;
  final bool isSelected;

  const _VideoPreviewPage({required this.file, required this.isSelected});

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '動画プレビュー',
          style: AppTypography.jpMMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 動画プレーヤー
          Center(
            child: _initialized
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          // 一時停止アイコン
          if (_initialized && !_controller.value.isPlaying)
            const Center(
              child: IgnorePointer(
                child: Icon(Icons.play_circle_outline,
                    color: Colors.white54, size: 72),
              ),
            ),
          // 選択ボタン
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(!widget.isSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.isSelected ? Colors.white : AppColors.accent,
                    foregroundColor:
                        widget.isSelected ? AppColors.accent : Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: widget.isSelected
                          ? const BorderSide(color: AppColors.accent)
                          : BorderSide.none,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isSelected ? '選択を解除する' : 'この動画を選択する',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── サムネイルウィジェット ────────────────────────────
class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(200),
    );
    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Container(color: const Color(0xFF2C2C2E));
    }
    return Image.memory(_data!, fit: BoxFit.cover);
  }
}
