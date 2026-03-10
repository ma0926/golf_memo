import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        // iOSではSF Pro（英字）とHiragino Sans（日本語）がシステムで自動切替されます
        fontFamily: 'HiraginoSans',
        tabBarTheme: const TabBarThemeData(
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.primary, width: 2.0),
            borderRadius: BorderRadius.zero,
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Color(0xFF4B5E96),
          dividerHeight: 0.3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Hiragino Sans',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Hiragino Sans',
          ),
        ),
        textTheme: const TextTheme(
          // 本文・カード内テキスト
          bodyMedium: TextStyle(
            fontFamily: 'HiraginoSans',
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          // 大見出し（画面タイトルなど）
          headlineMedium: TextStyle(
            fontFamily: 'HiraginoSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      );
}
