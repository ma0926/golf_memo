import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// メインアクションボタン（適用・保存・次へ など）
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final Widget? icon;

  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.primary,
    this.height = 44,
    this.borderRadius = 14,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: color,
      disabledBackgroundColor: color.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      padding: padding,
    );

    final labelText = Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );

    final loadingIndicator = const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );

    Widget button;
    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? loadingIndicator : icon!,
        label: labelText,
        style: buttonStyle,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: isLoading ? loadingIndicator : labelText,
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}

/// サブアクションボタン（クリア・キャンセル など）
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.textPrimary,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }
}
