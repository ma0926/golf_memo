import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        // iOSではSF Pro（英字）とHiragino Sans（日本語）がシステムで自動切替されます
        fontFamily: 'HiraginoSans',
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
