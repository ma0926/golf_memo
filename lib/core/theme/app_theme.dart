import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        // JP styles explicitly set 'Hiragino Sans'; EN styles omit fontFamily to use SF Pro
        tabBarTheme: const TabBarThemeData(
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.primary, width: 2.0),
            borderRadius: BorderRadius.zero,
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppColors.primaryMiddle,
          dividerHeight: 0.3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.jpSMedium,
          unselectedLabelStyle: AppTypography.jpSMedium,
        ),
        textTheme: const TextTheme(
          // 本文・カード内テキスト
          bodyMedium: AppTypography.jpSRegular,
          // 大見出し（画面タイトルなど）
          headlineMedium: AppTypography.jpHeader1,
        ),
      );
}
