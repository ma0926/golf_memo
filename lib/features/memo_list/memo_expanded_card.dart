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
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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

  @override
  Widget build(BuildContext context) {
    final memo = _memo;
    const weekdayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    final weekday = weekdayNames[memo.practicedAt.weekday - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
              // Section 1
              Text(
                weekday,
                style: AppTypography.jpSubHeader.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                _clubName,
                style: AppTypography.jpHeader1.copyWith(color: AppColors.textPrimary),
              ),
              // Section 2: media grid
              if (_mediaList.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ImageGrid(mediaList: _mediaList, docsPath: _docsPath),
              ],
              const SizedBox(height: 16),
              _MetaChipsRow(
                distance: memo.distance,
                condition: memo.condition,
                shotShape: memo.shotShape,
                wind: memo.wind,
              ),
              // Section 3: body text
              if (memo.body != null && memo.body!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  memo.body!,
                  style: AppTypography.jpMRegular.copyWith(color: AppColors.textMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── メタ情報行 ──────────────────────────────────────
class _MetaChipsRow extends StatelessWidget {
  final int? distance;
  final String? condition;
  final String? shotShape;
  final String? wind;

  const _MetaChipsRow({this.distance, this.condition, this.shotShape, this.wind});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (distance != null)
        Text(
          '${distance}yd',
          style: AppTypography.enHeader2.copyWith(
            color: AppColors.textPrimary,
            fontStyle: FontStyle.italic,
          ),
        ),
      if (shotShape != null)
        _MetaItem(
          svgPath: 'assets/icons/$shotShape.svg',
          label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!,
          iconTextGap: 0,
          applyColorFilter: true,
        ),
      if (condition != null)
        _MetaItem(
          icon: Icons.sentiment_satisfied_outlined,
          label: AppConstants.conditionLabels[condition] ?? condition!,
        ),
      if (wind != null)
        wind == 'none'
            ? const _MetaItem(
                svgPath: 'assets/icons/wind_none.svg',
                label: '風なし',
              )
            : _MetaItem(
                icon: Icons.air,
                label: AppConstants.windLabels[wind!] ?? wind!,
              ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items,
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final double iconTextGap;
  final bool applyColorFilter;

  const _MetaItem({
    this.icon,
    this.svgPath,
    required this.label,
    this.iconTextGap = 4,
    this.applyColorFilter = false,
  }) : assert(icon != null || svgPath != null);

  @override
  Widget build(BuildContext context) {
    final iconWidget = svgPath != null
        ? SvgPicture.asset(
            svgPath!,
            width: 16,
            height: 16,
            colorFilter: applyColorFilter
                ? const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn)
                : null,
          )
        : Icon(icon, size: 16, color: AppColors.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(width: iconTextGap),
        Text(
          label,
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
        ),
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

