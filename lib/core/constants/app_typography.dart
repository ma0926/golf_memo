import 'package:flutter/material.dart';

/// アプリ共通タイポグラフィ定義。
/// Figma Variables（GOLF Journal）より。
/// 色は含まない。使用時に copyWith で合成する。
///
/// 例:
/// ```dart
/// Text('クラブ名', style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary))
/// ```
class AppTypography {
  AppTypography._();

  // ── JP: Hiragino Sans ──────────────────────────────────────────────

  /// Header1: 24px / W6 / 行間120% — 画面タイトル・大見出し
  static const TextStyle jpHeader1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: 'Hiragino Sans',
    height: 1.2,
  );

  /// Header2: 20px / W6 / 行間120%
  static const TextStyle jpHeader2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: 'Hiragino Sans',
    height: 1.2,
  );

  /// Header3: 18px / W6 / 行間120% — カード内クラブ名・AppBarタイトル
  static const TextStyle jpHeader3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Hiragino Sans',
    height: 1.2,
  );

  /// Header4: 16px / W6 / 行間120% — 小見出し・ラベル見出し
  static const TextStyle jpHeader4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Hiragino Sans',
    height: 1.2,
  );

  /// SubHeader: 16px / W4 / 行間120% — サブ見出し・ラベル
  static const TextStyle jpSubHeader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Hiragino Sans',
    height: 1.2,
  );

  /// M/Medium: 16px / W5 / 行間150%
  static const TextStyle jpMMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Hiragino Sans',
    height: 1.5,
  );

  /// M/Regular: 16px / W4 / 行間150%
  static const TextStyle jpMRegular = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Hiragino Sans',
    height: 1.5,
  );

  /// S/Medium: 14px / W5 / 行間150%
  static const TextStyle jpSMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Hiragino Sans',
    height: 1.5,
  );

  /// S/Regular: 14px / W4 / 行間150%
  static const TextStyle jpSRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Hiragino Sans',
    height: 1.5,
  );

  // ── EN: SF Pro（iOSシステムフォント、fontFamily省略でSF Pro自動適用）────

  /// Header1: 24px / W7 / 行間120%
  static const TextStyle enHeader1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Header2: 20px / W7 / 行間120%
  static const TextStyle enHeader2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Header3: 18px / W7 / 行間120%
  static const TextStyle enHeader3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Header4: 16px / W7 / 行間120%
  static const TextStyle enHeader4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// M/Medium: 16px / W510 / 行間150%
  static const TextStyle enMMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 510)],
    height: 1.5,
  );

  /// M/Regular: 16px / W4 / 行間150%
  static const TextStyle enMRegular = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// S/Medium--100: 14px / W5 / 行間100% — 英数字・数値ラベル等
  static const TextStyle enSMedium100 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );
}
