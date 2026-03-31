import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/media_preview_screen.dart';
import '../memo_edit/memo_edit_screen.dart';

/// カードを展開したときに表示するコンテンツ。
/// MemoCard（閉じた状態）と同じ流れで OpenContainer の openBuilder に渡す。
class MemoExpandedCard extends StatefulWidget {
  final PracticeMemo memo;
  final String clubName;
  final VoidCallback? onChanged;

  const MemoExpandedCard({
    super.key,
    required this.memo,
    required this.clubName,
    this.onChanged,
  });

  @override
  State<MemoExpandedCard> createState() => _MemoExpandedCardState();
}

class _MemoExpandedCardState extends State<MemoExpandedCard>
    with SingleTickerProviderStateMixin {
  final _mediaRepo = MediaRepository();
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();

  late PracticeMemo _memo;
  late String _clubName;
  List<Media> _mediaList = [];
  late bool _isFavorite;
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );

  @override
  void initState() {
    super.initState();
    _memo = widget.memo;
    _clubName = widget.clubName;
    _isFavorite = widget.memo.isFavorite;
    _loadMedia();
    // カードの拡大アニメーション（400ms）が終わってからコンテンツをフェードイン
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  Future<void> _reload() async {
    if (_memo.id == null) return;
    final memo = await _memoRepo.getMemoById(_memo.id!);
    if (memo == null || !mounted) return;
    final club = await _clubRepo.getClubById(memo.clubId);
    final media = await _mediaRepo.getMediaByMemoId(_memo.id!);
    setState(() {
      _memo = memo;
      _clubName = club?.name ?? '不明なクラブ';
      _isFavorite = memo.isFavorite;
      _mediaList = media;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (_memo.id == null) return;
    final media = await _mediaRepo.getMediaByMemoId(_memo.id!);
    if (mounted) setState(() => _mediaList = media);
  }

  Future<void> _toggleFavorite() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    await _memoRepo.toggleFavorite(_memo.id!, newValue);
    widget.onChanged?.call();
  }

  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final size = MediaQuery.of(context).size;
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: false,
                backgroundColor: Colors.transparent,
                constraints: BoxConstraints(maxHeight: size.height * 0.92),
                builder: (_) => ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: MemoEditScreen(memoId: widget.memo.id!),
                ),
              );
              if (result == true) {
                await _reload();
                widget.onChanged?.call();
              }
            },
            child: const Text('編集'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _showDeleteConfirm();
            },
            child: const Text('削除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この記録を削除すると元に戻せません。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _mediaRepo.deleteMediaByMemoId(_memo.id!);
              await _memoRepo.deleteMemo(_memo.id!);
              if (mounted) {
                widget.onChanged?.call();
                Navigator.of(context).pop();
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memo = _memo;
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[memo.practicedAt.weekday - 1];
    final dateStr =
        '${memo.practicedAt.year}/${memo.practicedAt.month}/${memo.practicedAt.day}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/close.svg', width: 24, height: 24),
          onPressed: () => Navigator.of(context).pop(),
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
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _clubName,
                style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(dateStr,
                      style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(weekday,
                      style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              _MetaChipsRow(
                condition: memo.condition,
                distance: memo.distance,
                shotShape: memo.shotShape,
                wind: memo.wind,
              ),
              if (memo.body != null && memo.body!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  memo.body!,
                  style: AppTypography.jpMRegular.copyWith(color: AppColors.textMedium),
                ),
              ],
              if (_mediaList.isNotEmpty) ...[
                const SizedBox(height: 24),
                _MediaRow(mediaList: _mediaList),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── メタチップ行 ──────────────────────────────────────
class _MetaChipsRow extends StatelessWidget {
  final String? condition;
  final int? distance;
  final String? shotShape;
  final String? wind;

  const _MetaChipsRow(
      {this.condition, this.distance, this.shotShape, this.wind});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (distance != null)
        _MetaChip(icon: Icons.place_outlined, label: '${distance}yd'),
      if (shotShape != null)
        _MetaChip(
          icon: Icons.north_east,
          label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!,
        ),
      if (condition != null)
        _MetaChip(
          icon: Icons.sentiment_satisfied_outlined,
          label: AppConstants.conditionLabels[condition] ?? condition!,
        ),
      if (wind != null)
        _MetaChip(
          icon: Icons.air,
          label: AppConstants.windLabels[wind] ?? wind!,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLabel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.jpSRegular.copyWith(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── メディア横並びサムネイル ──────────────────────────
class _MediaRow extends StatelessWidget {
  final List<Media> mediaList;

  const _MediaRow({required this.mediaList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  pageBuilder: (_, __, ___) => MediaPreviewScreen(
                    file: thumbFile ?? imageFile,
                    isVideo: isVideo,
                    videoPath: isVideo ? item.uri : null,
                  ),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 92,
                height: 92,
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
                          child: Icon(Icons.videocam,
                              size: 36, color: AppColors.textSecondary),
                        ),
                      ),
                    if (isVideo)
                      const Center(
                        child: Icon(Icons.play_circle_filled,
                            size: 36, color: Colors.white70),
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

