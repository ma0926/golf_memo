import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// 記録一覧の1枚のカード
class MemoCard extends StatelessWidget {
  final String clubName;
  final String? distance;    // 例: "270yd"
  final String? bodyText;    // メモ本文（省略表示）
  final String? thumbnailPath; // サムネイル画像パス（任意）
  final VoidCallback onTap;

  const MemoCard({
    super.key,
    required this.clubName,
    this.distance,
    this.bodyText,
    this.thumbnailPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側：クラブ名・距離・メモ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // クラブ名 + 距離
                  Row(
                    children: [
                      Text(
                        clubName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 調子インジケーター（グリーンの四角）
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      if (distance != null)
                        Text(
                          distance!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  // メモ本文（1行で省略）
                  if (bodyText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      bodyText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 右側：サムネイル（あれば表示）
            if (thumbnailPath != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  thumbnailPath!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
