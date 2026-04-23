import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/media_grid.dart';
import '../../shared/widgets/memo_card.dart' show ClubBadge;
import '../../shared/widgets/sheet_drag_handle.dart';
import '../memo_edit/memo_edit_screen.dart';

/// カードを展開したときに表示するコンテンツ。
/// MemoCard（閉じた状態）と同じ流れで OpenContainer の openBuilder に渡す。
class MemoExpandedCard extends StatefulWidget {
  final PracticeMemo memo;
  final String clubName;
  final String? clubCategory;
  final bool clubIsCustom;
  final VoidCallback? onChanged;

  const MemoExpandedCard({
    super.key,
    required this.memo,
    required this.clubName,
    this.clubCategory,
    this.clubIsCustom = false,
    this.onChanged,
  });

  @override
  State<MemoExpandedCard> createState() => _MemoExpandedCardState();
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Text(
        label,
        style: AppTypography.jpSMedium.copyWith(color: const Color(0xFF2F5269)),
      ),
    );
  }
}

class _MemoExpandedCardState extends State<MemoExpandedCard>
    with SingleTickerProviderStateMixin {
  final _mediaRepo = MediaRepository();
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();

  late PracticeMemo _memo;
  late String _clubName;
  String? _clubCategory;
  bool _clubIsCustom = false;
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
    _clubCategory = widget.clubCategory;
    _clubIsCustom = widget.clubIsCustom;
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
      _clubCategory = club?.category;
      _clubIsCustom = club?.isCustom ?? false;
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
            const SheetDragHandle(),
            ListTile(
              minTileHeight: 48,
              leading: SvgPicture.asset(
                'assets/icons/edit.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
              ),
              title: Text(
                '編集',
                style: AppTypography.enMRegular.copyWith(color: AppColors.textPrimary),
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
              minTileHeight: 48,
              leading: SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              title: Text(
                '削除',
                style: AppTypography.enMRegular.copyWith(color: Colors.red),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    if (diff <= 6) return '$diff日前';
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
              // ヘッダー: バッジ + クラブ名 + 飛距離
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClubBadge(
                    name: _clubName,
                    category: _clubCategory,
                    isCustom: _clubIsCustom,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clubName,
                        style: AppTypography.jpSMedium.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            memo.distance != null ? '${memo.distance}' : '--',
                            style: AppTypography.enHeader4.copyWith(
                              color: memo.distance != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'yd',
                            style: AppTypography.enHeader4.copyWith(
                              color: memo.distance != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // 本文
              if (memo.body != null && memo.body!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  memo.body!.trim(),
                  style: AppTypography.jpMRegular.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                    wordSpacing: 0,
                  ),
                ),
              ],
              // メディア
              if (_mediaList.isNotEmpty) ...[
                const SizedBox(height: 16),
                MediaGrid(items: MediaGrid.fromMedia(_mediaList, _docsPath)),
              ],
              // メタチップ
              if (memo.shotShape != null || memo.condition != null || memo.wind != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    if (memo.shotShape != null)
                      _MetaChip(label: AppConstants.shotShapeLabels[memo.shotShape] ?? memo.shotShape!),
                    if (memo.condition != null)
                      _MetaChip(label: AppConstants.conditionLabels[memo.condition] ?? memo.condition!),
                    if (memo.wind != null)
                      _MetaChip(label: '風${AppConstants.windLabels[memo.wind] ?? memo.wind!}'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

