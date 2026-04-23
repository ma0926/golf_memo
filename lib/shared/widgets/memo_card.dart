import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import 'app_glass_card.dart';
import 'media_grid.dart';

export 'media_grid.dart' show MemoMediaItem;

// 記録一覧の1枚のカード
class MemoCard extends StatelessWidget {
  final String clubName;
  final String? clubCategory;
  final bool clubIsCustom;
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
    this.clubCategory,
    this.clubIsCustom = false,
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

  @override
  Widget build(BuildContext context) {
    final hasImages = mediaItems.isNotEmpty;
    final hasBody = bodyText != null && bodyText!.isNotEmpty;
    final hasMeta = shotShape != null || condition != null || wind != null;

    final content = Container(
      margin: margin,
      width: double.infinity,
      child: AppGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: バッジ + クラブ名 + 飛距離
            Padding(
              padding: EdgeInsets.only(
                bottom: (hasBody || hasImages || hasMeta) ? 4 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClubBadge(name: clubName, category: clubCategory, isCustom: clubIsCustom),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clubName,
                          style: AppTypography.jpSMedium.copyWith(
                            color: AppColors.textMedium,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              distance != null
                                  ? distance!.replaceAll('yd', '')
                                  : '--',
                              style: AppTypography.enHeader4.copyWith(
                                color: distance != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'yd',
                              style: AppTypography.enHeader4.copyWith(
                                color: distance != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasBody) ...[
              const SizedBox(height: 12),
              Text(
                bodyText!.replaceAll('\n', ' '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.jpMRegular.copyWith(color: AppColors.textMedium),
              ),
            ],
            if (hasImages) ...[
              const SizedBox(height: 12),
              MediaGrid(items: mediaItems),
            ],
            if (hasMeta) ...[
              const SizedBox(height: 12),
              _MetaChipRow(
                shotShape: shotShape,
                condition: condition,
                wind: wind,
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 12),
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
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ── クラブバッジ（左側の角丸正方形） ──────────────────
class ClubBadge extends StatelessWidget {
  final String name;
  final String? category;
  final bool isCustom;

  const ClubBadge({super.key, required this.name, this.category, this.isCustom = false});

  String get _shortName {
    if (isCustom) {
      return name.runes.take(2).map(String.fromCharCode).join();
    }
    if (name == 'ドライバー') return '1W';
    final match = RegExp(r'(\d+)番').firstMatch(name);
    final num = match?.group(1) ?? '';
    switch (category) {
      case 'ウッド':
        return '${num}W';
      case 'ユーティリティ':
        return '${num}U';
      case 'アイアン':
        return '${num}I';
      case 'ウェッジ':
        if (name.contains('ピッチング')) return 'PW';
        if (name.contains('アプローチ')) return 'AW';
        if (name.contains('サンド')) return 'SW';
        if (name.contains('ロブ')) return 'LW';
        return 'W';
      default:
        return name.runes.take(2).map(String.fromCharCode).join();
    }
  }

  Color get _badgeColor {
    switch (category) {
      case 'ウッド':        return const Color(0x4D8EABBD); // rgba(142,171,190,0.30)
      case 'アイアン':      return const Color(0x4D8EBEA5); // rgba(142,190,165,0.30)
      case 'ユーティリティ': return const Color(0x4DBEB78E); // rgba(190,183,142,0.30)
      case 'ウェッジ':      return const Color(0x4DBE8EBD); // rgba(190,142,189,0.30)
      default:              return const Color(0x4DA6A6A6); // rgba(166,166,166,0.30)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        _shortName,
        style: const TextStyle(
          fontFamily: 'SF Compact',
          fontSize: 16,
          fontWeight: FontWeight.w800, // 790 → w800 が最近似
          color: AppColors.textMedium,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── メタ情報チップ行 ────────────────────────────────────
class _MetaChipRow extends StatelessWidget {
  final String? shotShape;
  final String? condition;
  final String? wind;

  const _MetaChipRow({this.shotShape, this.condition, this.wind});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        if (shotShape != null)
          _MetaChip(label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!),
        if (condition != null)
          _MetaChip(label: AppConstants.conditionLabels[condition] ?? condition!),
        if (wind != null)
          _MetaChip(label: '風${AppConstants.windLabels[wind] ?? wind!}'),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background, // #F0F2F5
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.jpSMedium.copyWith(
              color: const Color(0xFF2F5269),
            ),
          ),
        ],
      ),
    );
  }
}
