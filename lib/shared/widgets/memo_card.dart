import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// 記録一覧の1枚のカード
// OpenContainer の closedBuilder 内で使う場合は onTap を省略する
class MemoCard extends StatelessWidget {
  final String clubName;
  final String? distance;
  final String? bodyText;
  final String? thumbnailPath;
  final bool isFavorite;
  final VoidCallback? onTap;          // null のとき GestureDetector を使わない
  final VoidCallback? onToggleFavorite;

  const MemoCard({
    super.key,
    required this.clubName,
    this.distance,
    this.bodyText,
    this.thumbnailPath,
    this.isFavorite = false,
    this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0C0C0D),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // クラブ名 + 飛距離
          Row(
            children: [
              Text(
                clubName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Hiragino Sans',
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (distance != null)
                Text(
                  distance!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Hiragino Sans',
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 本文 + サムネイル
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bodyText != null)
                      Text(
                        bodyText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Hiragino Sans',
                          color: AppColors.textBody,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // ブックマークボタン（タップは OpenContainer のタップと独立させる）
                    GestureDetector(
                      onTap: onToggleFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMiddle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                          color: isFavorite
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (thumbnailPath != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(thumbnailPath!),
                    width: 81,
                    height: 81,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // onTap が指定されている場合のみ GestureDetector でラップ
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
