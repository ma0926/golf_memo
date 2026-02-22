import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/memo_list/memo_list_screen.dart';
import 'features/memo_detail/memo_detail_screen.dart';
import 'features/memo_create/memo_create_screen.dart';
import 'features/memo_edit/memo_edit_screen.dart';
import 'features/search/search_screen.dart';
import 'features/report/report_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/club_settings_screen.dart';
import 'features/settings/custom_club_screen.dart';

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
    // 記録作成（下からスライドアップ・:idより先に定義する必要あり）
    GoRoute(
      path: '/memo/create',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const MemoCreateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    ),
    // 記録編集（下からスライドアップ）
    GoRoute(
      path: '/memo/:id/edit',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          child: MemoEditScreen(memoId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            );
          },
        );
      },
    ),
    // 記録詳細（右からスライドイン）
    GoRoute(
      path: '/memo/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          child: MemoDetailScreen(memoId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            );
          },
        );
      },
    ),
    // 検索（下からスライドアップ）
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
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
    // 練習するクラブ
    GoRoute(
      path: '/settings/clubs',
      builder: (context, state) => const ClubSettingsScreen(),
    ),
    // カスタムクラブ新規作成（:clubId より先に定義する必要あり）
    GoRoute(
      path: '/settings/clubs/new',
      builder: (context, state) => const CustomClubScreen(),
    ),
    // カスタムクラブ編集
    GoRoute(
      path: '/settings/clubs/:clubId/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['clubId']!);
        return CustomClubScreen(clubId: id);
      },
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
    );
  }
}
