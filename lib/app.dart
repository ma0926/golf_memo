import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';

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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter _buildRouter(String initialLocation) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    // オンボーディング（初回のみ）
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // ホーム・レポートをシェルで包み、ボトムナビを固定する
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => CustomTransitionPage(
        key: state.pageKey,
        child: _ScaffoldWithNav(navigationShell: navigationShell),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, child) => child,
      ),
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
    // 記録詳細（検索画面などから直接遷移する場合のフォールバック）
    GoRoute(
      path: '/memo/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MemoDetailScreen(memoId: id);
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
    // 設定（下からスライドイン）
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
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

// FABをナビバーから20px上に配置するカスタム位置
class _EndAboveNavBar extends FloatingActionButtonLocation {
  const _EndAboveNavBar();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width
        - scaffoldGeometry.floatingActionButtonSize.width
        - 16;
    final double fabY = scaffoldGeometry.contentBottom
        - scaffoldGeometry.floatingActionButtonSize.height
        - 20;
    return Offset(fabX, fabY);
  }
}

/// 詳細画面が開いているかどうか（BottomAppBar非表示に使用）
final isDetailOpen = ValueNotifier<bool>(false);

/// メモが作成されたことを通知する（一覧画面のリロード用）
final memoCreatedNotifier = ValueNotifier<int>(0);

// ── ボトムナビゲーション共有シェル ────────────────────
class _ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      // FABはメモ一覧タブのみ右下に表示
      floatingActionButton: navigationShell.currentIndex == 0
          ? ValueListenableBuilder<bool>(
              valueListenable: isDetailOpen,
              builder: (_, open, child) => AnimatedOpacity(
                opacity: open ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(ignoring: open, child: child),
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: MemoCreateScreen(),
                      ),
                      transitionsBuilder: (_, animation, __, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                  );
                  if (result == true) {
                    memoCreatedNotifier.value++;
                  }
                },
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 3,
                child: SvgPicture.asset(
                  'assets/icons/add_2.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: const _EndAboveNavBar(),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: isDetailOpen,
        builder: (_, open, child) => AnimatedOpacity(
          opacity: open ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(ignoring: open, child: child),
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.33,
            color: const Color(0x4D000000), // #000000 30%opacity
          ),
          ColoredBox(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 49, // iOS標準タブバー高さ
                child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => navigationShell.goBranch(0),
                      child: _NavItem(
                        icon: 'assets/icons/view_agenda.svg',
                        label: 'ホーム',
                        selected: navigationShell.currentIndex == 0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => navigationShell.goBranch(1),
                      child: _NavItem(
                        icon: 'assets/icons/show_chart.svg',
                        label: 'レポート',
                        selected: navigationShell.currentIndex == 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SearchScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          transitionsBuilder: (_, __, ___, child) => child,
                        ),
                      ),
                      child: const _NavItem(
                        icon: 'assets/icons/Icon Button-1.svg',
                        label: '検索',
                        selected: false,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SettingsScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          transitionsBuilder: (_, __, ___, child) => child,
                        ),
                      ),
                      child: const _NavItem(
                        icon: 'assets/icons/Icon Button.svg',
                        label: '設定',
                        selected: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
      ),
    );
  }
}

// ── ナビバーアイテム（アイコン＋ラベル）────────────────
class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 25,
            height: 25,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class App extends StatefulWidget {
  final String initialRoute;
  const App({super.key, required this.initialRoute});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(widget.initialRoute);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PIN',
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('ja', 'JP'),
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
