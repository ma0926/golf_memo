import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // スプラッシュを最低 1.5 秒表示しつつ、初回フラグを確認
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;
    final prefs = results[1] as SharedPreferences;
    final completed = prefs.getBool('onboarding_completed') ?? false;
    context.go(completed ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Text(
          'Golf Memo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
