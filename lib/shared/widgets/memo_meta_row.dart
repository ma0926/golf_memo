import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// メモの飛距離・球筋・調子・風を表示する行。
/// 飛距離は左端、球筋/調子/風は右端。
class MemoMetaRow extends StatelessWidget {
  final int? distance;
  final String? shotShape;
  final String? condition;
  final String? wind;

  const MemoMetaRow({
    super.key,
    this.distance,
    this.shotShape,
    this.condition,
    this.wind,
  });

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
