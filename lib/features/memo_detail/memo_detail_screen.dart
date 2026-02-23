import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/media_preview_screen.dart';

class MemoDetailScreen extends StatefulWidget {
  final int memoId;

  const MemoDetailScreen({super.key, required this.memoId});

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();
  final _mediaRepo = MediaRepository();

  PracticeMemo? _memo;
  String _clubName = '';
  List<Media> _mediaList = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memo = await _memoRepo.getMemoById(widget.memoId);
    if (memo == null) {
      if (mounted) context.go('/home');
      return;
    }
    final club = await _clubRepo.getClubById(memo.clubId);
    final media = await _mediaRepo.getMediaByMemoId(widget.memoId);

    setState(() {
      _memo = memo;
      _clubName = club?.name ?? '不明なクラブ';
      _mediaList = media;
      _isFavorite = memo.isFavorite;
      _isLoading = false;
    });
  }

  // 「...」アクションシート
  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final result = await context.push<bool>('/memo/${widget.memoId}/edit');
              if (result == true && mounted) _load();
            },
            child: const Text('編集'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirm();
            },
            child: const Text('削除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // 削除確認
  void _showDeleteConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この記録を削除すると元に戻せません。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _mediaRepo.deleteMediaByMemoId(widget.memoId);
              await _memoRepo.deleteMemo(widget.memoId);
              if (mounted) context.go('/home');
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  // お気に入り切り替え
  Future<void> _toggleFavorite() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    await _memoRepo.toggleFavorite(widget.memoId, newValue);
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.year}/${dt.month}/${dt.day}（$w）';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final memo = _memo!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: _showActionSheet,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.primary,
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // クラブ名
            Text(
              _clubName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // 日付
            Text(
              _formatDate(memo.practicedAt),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // メタ情報
            _MetaInfoRow(
              condition: memo.condition,
              distance: memo.distance,
              shotShape: memo.shotShape,
              wind: memo.wind,
            ),
            if (memo.body != null && memo.body!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                memo.body!,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
            ],
            // メディア横並び
            if (_mediaList.isNotEmpty) ...[
              const SizedBox(height: 24),
              _MediaRow(mediaList: _mediaList),
            ],
          ],
        ),
      ),
    );
  }
}

// ── メタ情報の横並び行 ──────────────────────────────────
class _MetaInfoRow extends StatelessWidget {
  final String? condition;
  final int? distance;
  final String? shotShape;
  final String? wind;

  const _MetaInfoRow({this.condition, this.distance, this.shotShape, this.wind});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (condition != null)
          _MetaChip(
            icon: Icons.thumb_up_outlined,
            label: AppConstants.conditionLabels[condition] ?? condition!,
          ),
        if (distance != null)
          _MetaChip(icon: Icons.place_outlined, label: '${distance}yd'),
        if (shotShape != null)
          _MetaChip(
            icon: Icons.north_east,
            label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!,
          ),
        if (wind != null)
          _MetaChip(
            icon: Icons.air,
            label: AppConstants.windLabels[wind] ?? wind!,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── メディア横並びサムネイル ────────────────────────────
class _MediaRow extends StatelessWidget {
  final List<Media> mediaList;

  const _MediaRow({required this.mediaList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        separatorBuilder: (_, i) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final item = mediaList[index];
          final isVideo = item.isVideo;
          final thumbFile = isVideo && item.thumbnailUri != null
              ? File(item.thumbnailUri!)
              : null;
          final imageFile = !isVideo ? File(item.uri) : null;

          return GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => MediaPreviewScreen(
                    file: thumbFile ?? imageFile,
                    isVideo: isVideo,
                    videoPath: isVideo ? item.uri : null,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageFile != null)
                      Image.file(imageFile, fit: BoxFit.cover)
                    else if (thumbFile != null)
                      Image.file(thumbFile, fit: BoxFit.cover)
                    else
                      Container(
                        color: AppColors.divider,
                        child: const Center(
                          child: Icon(Icons.videocam, size: 36, color: AppColors.textSecondary),
                        ),
                      ),
                    if (isVideo)
                      const Center(
                        child: Icon(Icons.play_circle_filled, size: 36, color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
