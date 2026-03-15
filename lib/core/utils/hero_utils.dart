import 'package:flutter/material.dart';

/// Hero飛行中のシャトルウィジェット
/// 開く時: 詳細画面コンテンツがフェードイン
/// 閉じる時: 詳細画面コンテンツがフェードアウト
Widget heroFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromCtx,
  BuildContext toCtx,
) {
  final isPop = direction == HeroFlightDirection.pop;

  // 詳細画面(Scaffold)側のコンテキストを選択
  final scaffoldCtx = isPop ? fromCtx : toCtx;
  final scaffoldSize = (scaffoldCtx.findRenderObject() as RenderBox?)?.size
      ?? MediaQuery.sizeOf(flightContext);
  final scaffoldChild = (scaffoldCtx.widget as Hero).child;

  return AnimatedBuilder(
    animation: animation,
    builder: (_, __) {
      final radius = isPop
          ? 16.0 * animation.value          // 閉じる: 0→16
          : 16.0 * (1.0 - animation.value); // 開く:   16→0

      final opacity = isPop
          ? (1.0 - animation.value / 0.08).clamp(0.0, 1.0) // 閉じる: 8%地点で完了
          : animation.value;                              // 開く:   0→1（フェードイン）

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: scaffoldSize.width,
            height: scaffoldSize.height,
            child: opacity > 0
                ? Opacity(
                    opacity: opacity,
                    child: scaffoldChild,
                  )
                : null,
          ),
        ),
      );
    },
  );
}
