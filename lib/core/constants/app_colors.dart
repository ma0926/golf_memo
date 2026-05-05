import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── ブランド ──────────────────────────────────────────
  // Figma: Primary/High
  static const Color primary         = Color(0xFF23264E);
  // Figma: Primary/Middle
  static const Color primaryMiddle   = Color(0xFF4B5E96);
  // Figma: Accent
  static const Color accent          = Color(0xFF415196);
  // Figma: Colors/Red（Destructive）
  static const Color destructive     = Color(0xFFFF3B30);

  // ── テキスト ─────────────────────────────────────────
  // Figma: Text/High
  static const Color textPrimary     = Color(0xFF131618);
  // Figma: Text/Medium
  static const Color textMedium      = Color(0xFF353B40);
  // Figma: Text/Low
  static const Color textSecondary   = Color(0xFF5E6871);
  // Figma: Text/Placeholder
  static const Color textPlaceholder = Color(0xFF91989F);
  // 本文テキスト（カード内メモ）
  static const Color textBody        = Color(0xFF474747);

  // ── 背景 ─────────────────────────────────────────────
  // Figma: Background/Ex-Low
  static const Color backgroundExLow = Color(0xFFFCFCFD);
  // Figma: Background/Low
  static const Color background      = Color(0xFFF0F2F5);
  // Figma: Background/Middle
  static const Color backgroundMiddle = Color(0xFFE6EAEE);
  // Figma: Backgrounds/Primary（カード・シート・入力エリア）
  static const Color cardBackground  = Color(0xFFFFFFFF);
  // メタチップ背景
  static const Color backgroundLabel = Color(0xFFEBF2F8);

  // ── ボーダー・セパレーター ───────────────────────────
  // Figma: Boder/Middle（カードの枠線・区切り線）
  static const Color divider         = Color(0xFFE1E1E5);
  // Figma: Boder/High
  static const Color borderHigh      = Color(0xFFD4D4D6);
}
