import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// アプリ共通リストアイテム。
/// 高さ48px・左右padding無し・16px textPrimary で統一。
class AppListTile extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const AppListTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 48,
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        title,
        style: AppTypography.jpMRegular.copyWith(
          fontSize: 16,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
