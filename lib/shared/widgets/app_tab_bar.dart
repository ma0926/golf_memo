import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// メモ一覧・レポートで共通使用するセグメントタブ。
/// TabController を使わないシンプルな実装（コールバック方式）。
/// メモ一覧の TabBar と同じ見た目：フル幅均等・高さ38・アンダーライン2px・divider 0.3px。
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: labels.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  // Flutter TabBar と高さを合わせる：38px 内に下線を内包
                  child: SizedBox(
                    height: 38,
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            label,
                            style: AppTypography.jpHeader4.copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: isSelected
                                ? AppColors.textPrimary
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          height: 0.3,
          color: AppColors.primaryMiddle,
        ),
      ],
    );
  }
}
