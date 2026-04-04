import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
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
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D7DE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/edit.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
              ),
              title: Text(
                '編集',
                style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => MemoEditScreen(memoId: widget.memoId),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                );
                if (result == true && mounted) _load();
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              title: Text(
                '削除',
                style: AppTypography.jpMRegular.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm();
              },
            ),
            const SizedBox(height: 8),
          ],
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

  String _formatDate(DateTime dt) => '${dt.year}/${dt.month}/${dt.day}';

  String _weekday(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[dt.weekday - 1];
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: SvgPicture.asset('assets/icons/close.svg', width: 30, height: 30),
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
        body: SingleChildScrollView(
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
                  Text(
                    _formatDate(memo.practicedAt),
                    style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _weekday(memo.practicedAt),
                    style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
    final spaced = <Widget>[];
    for (var i = 0; i < chips.length; i++) {
      spaced.add(Expanded(
        child: Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: chips[i],
          ),
        ),
      ));
      if (i < chips.length - 1) spaced.add(const SizedBox(width: 4));
    }
    return Row(children: spaced);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLabel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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

// ── メディア横並びサムネイル ────────────────────────────
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
        separatorBuilder: (_, i) => const SizedBox(width: 8),
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
