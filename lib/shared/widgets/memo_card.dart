import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

// 記録一覧の1枚のカード
class MemoCard extends StatelessWidget {
  final String clubName;
  final String? distance;
  final String? bodyText;
  final String? thumbnailPath;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const MemoCard({
    super.key,
    required this.clubName,
    this.distance,
    this.bodyText,
    this.thumbnailPath,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: Color(0x0A007BFF),
            blurRadius: 40,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // クラブ名 + 飛距離
          Row(
            children: [
              Expanded(
                child: Text(
                  clubName,
                  style: AppTypography.jpHeader4.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 8),
                Text(
                  distance!,
                  style: AppTypography.enHeader4.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
          if (bodyText != null && bodyText!.isNotEmpty || thumbnailPath != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bodyText != null && bodyText!.isNotEmpty)
                  Expanded(
                    child: Text(
                      bodyText!.replaceAll('\n', ' '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.jpMRegular.copyWith(color: AppColors.textMedium),
                    ),
                  )
                else if (thumbnailPath != null)
                  const Spacer(),
                if (thumbnailPath != null) ...[
                  if (bodyText != null && bodyText!.isNotEmpty) const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(thumbnailPath!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
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
