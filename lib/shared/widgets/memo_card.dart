import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import 'media_preview_screen.dart';

/// メディアアイテムの表示情報
typedef MemoMediaItem = ({String displayPath, bool isVideo, String? videoPath});

// 記録一覧の1枚のカード
class MemoCard extends StatelessWidget {
  final String clubName;
  final List<MemoMediaItem> mediaItems;
  final String? distance;
  final String? shotShape;
  final String? condition;
  final String? wind;
  final String? bodyText;
  final String? date;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const MemoCard({
    super.key,
    required this.clubName,
    this.mediaItems = const [],
    this.distance,
    this.shotShape,
    this.condition,
    this.wind,
    this.bodyText,
    this.date,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

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
    final item = mediaItems[index];
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

  Widget _buildImageGrid(BuildContext context) {
    final count = mediaItems.length.clamp(0, 4);
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

  @override
  Widget build(BuildContext context) {
    final hasImages = mediaItems.isNotEmpty;
    final hasMeta = distance != null || shotShape != null || condition != null || wind != null;
    final hasBody = bodyText != null && bodyText!.isNotEmpty;

    final content = Container(
      margin: margin,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset.zero),
          BoxShadow(color: Color(0x0A007BFF), blurRadius: 40, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clubName,
            style: AppTypography.jpHeader4.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          if (hasBody) ...[
            const SizedBox(height: 8),
            Text(
              bodyText!.replaceAll('\n', ' '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.jpMRegular.copyWith(color: AppColors.textMedium),
            ),
          ],
          if (distance != null || shotShape != null || condition != null || wind != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (distance != null)
                  Text(
                    distance!,
                    style: AppTypography.enMMedium.copyWith(color: AppColors.textPrimary),
                  ),
                if (shotShape != null || condition != null || wind != null) ...[
                  const Spacer(),
                  _MemoMetaRow(
                    shotShape: shotShape,
                    condition: condition,
                    wind: wind,
                  ),
                ],
              ],
            ),
          ],
          if (hasImages) ...[
            const SizedBox(height: 16),
            _buildImageGrid(context),
          ],
          if (date != null) ...[
            const SizedBox(height: 16),
            Text(
              date!,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Hiragino Sans',
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ── メタ情報行（一覧カード用） ─────────────────────────
class _MemoMetaRow extends StatelessWidget {
  final String? shotShape;
  final String? condition;
  final String? wind;

  const _MemoMetaRow({this.shotShape, this.condition, this.wind});

  IconData _conditionIcon(String cond) {
    switch (cond) {
      case 'good': return Icons.sentiment_satisfied_alt;
      case 'bad': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
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
      ],
    );
  }
}
