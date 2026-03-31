import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundMiddle,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "GOLF" テキスト
            const Text(
              'GOLF',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131618),
                height: 1.0,
                letterSpacing: 4,
              ),
            ),
            // "Journal" テキスト（イタリック）
            const Text(
              'Journal',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 42,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Color(0xFF131618),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 64),
            // ゴルフボールとティーのイラスト
            SvgPicture.asset(
              'assets/icons/golf_tee.svg',
              width: 130,
              height: 145,
            ),
          ],
        ),
      ),
    );
  }
}

