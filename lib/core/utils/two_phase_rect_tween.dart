import 'package:flutter/material.dart';

/// 開く時:  フェーズ1=均等スケールアップ、フェーズ2=高さ拡張
/// 閉じる時: フェーズ1=均等スケールダウン（高さ比率で劇的に）、フェーズ2=幅拡張+位置移動
class TwoPhaseRectTween extends Tween<Rect?> {
  TwoPhaseRectTween({required Rect? begin, required Rect? end})
      : super(begin: begin, end: end);

  @override
  Rect? lerp(double t) {
    final b = begin;
    final e = end;
    if (b == null || e == null) return null;

    final isClosing = e.width < b.width;

    if (isClosing) {
      // ── 閉じる時 ─────────────────────────────────────────
      // フェーズ1: 高さ比率で均等スケールダウン（視覚的に明確）
      // フェーズ2: 幅をカード幅に広げながらカード位置へ移動
      final scaleH = e.height / b.height; // 例: 90/844 ≈ 0.107
      final mid = Rect.fromCenter(
        center: b.center, // フェーズ1はスクリーン中心に固定
        width: b.width * scaleH,
        height: b.height * scaleH, // = e.height
      );

      if (t <= 0.5) {
        // フェーズ1: 均等スケール（中心固定）
        final p = Curves.easeInOut.transform(t * 2);
        return Rect.fromCenter(
          center: b.center,
          width: b.width + (mid.width - b.width) * p,
          height: b.height + (mid.height - b.height) * p,
        );
      } else {
        // フェーズ2: 高さ固定で幅を拡張しカード位置へ
        final p = Curves.easeInOut.transform((t - 0.5) * 2);
        return Rect.fromCenter(
          center: Offset.lerp(mid.center, e.center, p)!,
          width: mid.width + (e.width - mid.width) * p,
          height: e.height,
        );
      }
    } else {
      // ── 開く時 ───────────────────────────────────────────
      // フェーズ1: 幅比率で均等スケールアップ
      // フェーズ2: 高さ拡張してスクリーン位置へ
      final scaleW = e.width / b.width;
      final mid = Rect.fromCenter(
        center: b.center,
        width: e.width,
        height: b.height * scaleW,
      );

      if (t <= 0.5) {
        // フェーズ1: 均等スケール
        final p = Curves.easeInOut.transform(t * 2);
        return Rect.fromCenter(
          center: b.center,
          width: b.width + (mid.width - b.width) * p,
          height: b.height + (mid.height - b.height) * p,
        );
      } else {
        // フェーズ2: 高さ拡張+中心移動
        final p = Curves.easeInOut.transform((t - 0.5) * 2);
        return Rect.fromCenter(
          center: Offset.lerp(mid.center, e.center, p)!,
          width: e.width,
          height: mid.height + (e.height - mid.height) * p,
        );
      }
    }
  }
}
