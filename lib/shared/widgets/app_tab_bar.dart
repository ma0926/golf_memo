import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// メモ一覧・レポートで共通使用するセグメントタブ。
/// TabController を使わないシンプルな実装（コールバック方式）。
class AppTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: labels.asMap().entries.map((entry) {
            final i = entry.key;
            final label = entry.value;
            final isSelected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 38,
                    child: Center(
                      child: Text(
                        label,
                        style: AppTypography.jpHeader4.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    // アンダーラインの幅はテキスト幅 + 左右余白分
                    constraints: const BoxConstraints(minWidth: 44),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: isSelected ? AppColors.textPrimary : Colors.transparent,
                  ),
                ],
              ),
            );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 0.3,
          color: AppColors.primaryMiddle,
        ),
      ],
    );
  }
}
