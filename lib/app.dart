import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
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
import 'features/settings/terms_screen.dart';

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
    // ホーム・レポートをシェルで包み、ボトムナビを固定する
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithNav(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const MemoListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/report',
              builder: (context, state) => const ReportScreen(),
            ),
          ],
        ),
      ],
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
    // 記録詳細（Container Transform 近似: FadeScale）
    GoRoute(
      path: '/memo/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          child: MemoDetailScreen(memoId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeScaleTransition(animation: animation, child: child);
          },
        );
      },
    ),
    // 検索（Container Transform: スケール＋フェード）
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    // 設定（Container Transform: スケール＋フェード）
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    // 練習するクラブ
    GoRoute(
      path: '/settings/clubs',
      builder: (context, state) => const ClubSettingsScreen(),
    ),
    // 規約・ライセンス
    GoRoute(
      path: '/settings/terms',
      builder: (context, state) => const TermsScreen(),
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

// ── ボトムナビゲーション共有シェル ────────────────────
class _ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/memo/create'),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  navigationShell.currentIndex == 0
                      ? Icons.list_alt_outlined
                      : Icons.list_alt_outlined,
                ),
                color: navigationShell.currentIndex == 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
                onPressed: () => navigationShell.goBranch(0),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: Icon(
                  navigationShell.currentIndex == 1
                      ? Icons.trending_up
                      : Icons.trending_up_outlined,
                ),
                color: navigationShell.currentIndex == 1
                    ? AppColors.primary
                    : AppColors.textSecondary,
                onPressed: () => navigationShell.goBranch(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PIN',
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
