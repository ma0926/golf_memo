import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// 飛距離入力フォーム（記録作成・編集で共通使用）
class AppDistanceInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onClose;

  const AppDistanceInput({
    super.key,
    required this.controller,
    required this.onClose,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F3F5)),
        ),
        child: Row(
          children: [
            Text(
              '飛距離',
              style: AppTypography.jpHeader4.copyWith(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'yd',
              style: AppTypography.enMMedium.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, size: 20, color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }
}
