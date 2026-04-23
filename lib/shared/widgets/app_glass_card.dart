import 'package:flutter/material.dart';

/// グラスモーフィズムカード
/// background: rgba(255,255,255,0.80)
/// border: 1px solid #ffffff, border-radius: 24px
/// ※シャドウは OpenContainer のクリップを避けるため呼び出し側で付与する
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF), // rgba(255,255,255,0.80)
        borderRadius: radius,
        border: Border.all(
          color: const Color(0xFFFFFFFF), // #ffffff
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
