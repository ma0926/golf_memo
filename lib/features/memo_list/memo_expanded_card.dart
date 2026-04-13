import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/media_path_helper.dart';
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
  String _docsPath = '';
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
    final docsDir = await getApplicationDocumentsDirectory();
    if (mounted) setState(() {
      _mediaList = media;
      _docsPath = docsDir.path;
    });
  }

  Future<void> _toggleFavorite() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    await _memoRepo.toggleFavorite(_memo.id!, newValue);
    widget.onChanged?.call();
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
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
                    pageBuilder: (_, __, ___) => MemoEditScreen(memoId: widget.memo.id!),
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (_, animation, __, child) => FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                      child: child,
                    ),
                  ),
                );
                if (result == true) {
                  await _reload();
                  widget.onChanged?.call();
                }
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

  String _formattedDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.month}/${dt.day}（$w）';
  }

  @override
  Widget build(BuildContext context) {
    final memo = _memo;

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
            icon: SvgPicture.asset('assets/icons/more_horiz.svg', width: 30, height: 30),
            onPressed: _showActionSheet,
          ),
          IconButton(
            icon: SvgPicture.asset(
              _isFavorite ? 'assets/icons/bookmark.svg' : 'assets/icons/bookmark_border.svg',
              width: 24,
              height: 24,
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
              Center(
                child: Text(
                  _formattedDate(memo.practicedAt),
                  style: AppTypography.jpSMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'memo_club_${_memo.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    _clubName,
                    style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
              if (memo.body != null && memo.body!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  memo.body!,
                  style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary, letterSpacing: 0, wordSpacing: 0),
                ),
              ],
              if (memo.distance != null || memo.shotShape != null || memo.condition != null || memo.wind != null) ...[
                SizedBox(height: (memo.body != null && memo.body!.isNotEmpty) ? 12 : 16),
                _MetaInfoRow(
                  condition: memo.condition,
                  distance: memo.distance,
                  shotShape: memo.shotShape,
                  wind: memo.wind,
                ),
              ],
              if (_mediaList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Hero(
                  tag: 'memo_images_${_memo.id}',
                  child: _ImageGrid(mediaList: _mediaList, docsPath: _docsPath),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── メタ情報行（飛距離左・球筋/調子/風右） ──────────────────
class _MetaInfoRow extends StatelessWidget {
  final String? condition;
  final int? distance;
  final String? shotShape;
  final String? wind;

  const _MetaInfoRow({this.condition, this.distance, this.shotShape, this.wind});

  IconData _conditionIcon(String cond) {
    switch (cond) {
      case 'good': return Icons.sentiment_satisfied_alt;
      case 'bad': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaItems = <Widget>[
      if (shotShape != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(
            'assets/icons/$shotShape.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(AppColors.textMedium, BlendMode.srcIn),
          ),
          const SizedBox(width: 3),
          Text(
            AppConstants.shotShapeLabels[shotShape] ?? shotShape!,
            style: AppTypography.jpSRegular.copyWith(color: AppColors.textMedium),
          ),
        ]),
      if (condition != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_conditionIcon(condition!), size: 16, color: AppColors.textMedium),
          const SizedBox(width: 3),
          Text(
            AppConstants.conditionLabels[condition] ?? condition!,
            style: AppTypography.jpSRegular.copyWith(color: AppColors.textMedium),
          ),
        ]),
      if (wind != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(
            AppConstants.windIcons[wind] ?? 'assets/icons/wind_yes.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(AppColors.textMedium, BlendMode.srcIn),
          ),
          const SizedBox(width: 3),
          Text(
            AppConstants.windLabels[wind] ?? wind!,
            style: AppTypography.jpSRegular.copyWith(color: AppColors.textMedium),
          ),
        ]),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (distance != null)
          Text(
            '${distance}yd',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontVariations: [FontVariation('ital', 0.0)],
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        if (metaItems.isNotEmpty) ...[
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: metaItems,
          ),
        ],
      ],
    );
  }
}

// ── 画像グリッド ─────────────────────────────────────
class _ImageGrid extends StatelessWidget {
  final List<Media> mediaList;
  final String docsPath;

  const _ImageGrid({required this.mediaList, required this.docsPath});

  void _openPreview(BuildContext context, Media item) {
    final thumbPath = item.isVideo && item.thumbnailUri != null
        ? MediaPathHelper.resolve(item.thumbnailUri!, docsPath)
        : null;
    final imagePath = !item.isVideo
        ? MediaPathHelper.resolve(item.uri, docsPath)
        : null;
    final videoPath = item.isVideo
        ? MediaPathHelper.resolve(item.uri, docsPath)
        : null;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => MediaPreviewScreen(
          file: thumbPath != null ? File(thumbPath) : (imagePath != null ? File(imagePath) : null),
          isVideo: item.isVideo,
          videoPath: videoPath,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _imgTile(BuildContext context, int index) {
    final item = mediaList[index];
    final thumbPath = item.isVideo && item.thumbnailUri != null
        ? MediaPathHelper.resolve(item.thumbnailUri!, docsPath)
        : null;
    final imagePath = !item.isVideo
        ? MediaPathHelper.resolve(item.uri, docsPath)
        : null;
    final displayPath = thumbPath ?? imagePath;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPreview(context, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (displayPath != null)
            Image.file(
              File(displayPath),
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
    final count = mediaList.length.clamp(0, 4);
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

