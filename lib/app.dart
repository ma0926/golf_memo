import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/memo_list/memo_list_screen.dart';
import 'features/memo_detail/memo_detail_screen.dart';
import 'features/memo_create/memo_create_screen.dart';
import 'features/search/search_screen.dart';
import 'features/report/report_screen.dart';
import 'features/settings/settings_screen.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // スプラッシュ
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // オンボーディング（初回のみ）
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // ホーム（タブ付き記録一覧）
    GoRoute(
      path: '/home',
      builder: (context, state) => const MemoListScreen(),
    ),
    // 記録作成（:idより先に定義する必要あり）
    GoRoute(
      path: '/memo/create',
      builder: (context, state) => const MemoCreateScreen(),
    ),
    // 記録詳細（Sheet形式で表示）
    GoRoute(
      path: '/memo/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CupertinoPage(
          fullscreenDialog: true,
          child: MemoDetailScreen(memoId: id),
        );
      },
    ),
    // 検索
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    // レポート
    GoRoute(
      path: '/report',
      builder: (context, state) => const ReportScreen(),
    ),
    // 設定
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ゴルフ練習メモ',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
