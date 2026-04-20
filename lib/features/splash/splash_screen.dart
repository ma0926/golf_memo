import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // 1.0 → 0.0 でフェードアウト
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;
    final prefs = results[1] as SharedPreferences;
    final completed = prefs.getBool('onboarding_completed') ?? false;

    // フェードアウト完了を待ってから遷移
    await _controller.forward();
    if (!mounted) return;
    context.go(completed ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: AppColors.backgroundMiddle,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 88,
                height: 98,
              ),
              const SizedBox(height: 8),
              const Text(
                'My GOLF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 32,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF23264E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
