import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/memo_card.dart';
import 'memo_expanded_card.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/media_path_helper.dart';
import '../../app.dart' show isDetailOpen, memoCreatedNotifier;
import '../settings/settings_screen.dart';
import '../search/search_screen.dart';

// 日付ごとのグループ
class _DateGroup {
  final DateTime date;
  final List<PracticeMemo> memos;
  _DateGroup(this.date, this.memos);
}

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          titleSpacing: 16,
          title: Text(
            '練習記録',
            style: AppTypography.jpHeader1.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: SvgPicture.asset('assets/icons/Icon Button.svg', width: 48, height: 48),
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: SvgPicture.asset('assets/icons/Icon Button-1.svg', width: 48, height: 48),
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SearchScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.textPrimary, width: 2.0),
              borderRadius: BorderRadius.zero,
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.primaryMiddle,
            dividerHeight: 0.3,
            labelStyle: AppTypography.jpHeader4,
            unselectedLabelStyle: AppTypography.jpHeader4,
            tabs: [
              Tab(text: 'すべて', height: 38),
              Tab(text: 'お気に入り', height: 38),
            ],
          ),
        ),
        body: Stack(
          children: [
            const TabBarView(
              children: [
                _AllMemosTab(),
                _FavoriteMemosTab(),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isDetailOpen,
              builder: (_, open, __) => IgnorePointer(
                child: AnimatedOpacity(
                  opacity: open ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const SizedBox.expand(
                    child: ColoredBox(color: Color(0xD9FFFFFF)),
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

// ── すべてのメモ一覧 ──────────────────────────────────
class _AllMemosTab extends StatefulWidget {
  const _AllMemosTab();

  @override
  State<_AllMemosTab> createState() => _AllMemosTabState();
}

class _AllMemosTabState extends State<_AllMemosTab> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();
  final _mediaRepo = MediaRepository();

  List<PracticeMemo> _memos = [];
  Map<int, String> _clubNames = {};
  Map<int, String?> _thumbnails = {};
  bool _isLoading = true;
  int? _hiddenMemoId;

  @override
  void initState() {
    super.initState();
    _load();
    memoCreatedNotifier.addListener(_load);
  }

  @override
  void dispose() {
    memoCreatedNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final memos = await _memoRepo.getAllMemos();
    final clubs = await _clubRepo.getActiveClubs();

    final mediaResults = await Future.wait(
      memos.map((m) => m.id != null
          ? _mediaRepo.getMediaByMemoId(m.id!)
          : Future.value([])),
    );

    final docsDir = await getApplicationDocumentsDirectory();
    final thumbnails = <int, String?>{};
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      if (memo.id != null && mediaResults[i].isNotEmpty) {
        final first = mediaResults[i].first;
        final rawPath = first.isVideo ? first.thumbnailUri : first.uri;
        if (rawPath != null) {
          thumbnails[memo.id!] = MediaPathHelper.resolve(rawPath, docsDir.path);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _thumbnails = thumbnails;
      _isLoading = false;
      _hiddenMemoId = null;
    });
  }

  Future<void> _toggleFavorite(PracticeMemo memo) async {
    if (memo.id == null) return;
    await _memoRepo.toggleFavorite(memo.id!, !memo.isFavorite);
    await _load();
  }

  List<_DateGroup> get _grouped {
    final map = <String, _DateGroup>{};
    final order = <String>[];
    for (final memo in _memos) {
      final dt = memo.practicedAt;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (!map.containsKey(key)) {
        map[key] = _DateGroup(dt, []);
        order.add(key);
      }
      map[key]!.memos.add(memo);
    }
    return order.map((k) => map[k]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_memos.isEmpty) {
      return Center(
        child: Text(
          'まだ記録がありません\n＋ボタンから追加しましょう',
          textAlign: TextAlign.center,
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary, height: 1.8),
        ),
      );
    }

    final groups = _grouped;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 24, bottom: 80),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(date: group.date),
              ...group.memos.map((memo) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OpenContainer<bool>(
                      transitionDuration: const Duration(milliseconds: 400),
                      transitionType: ContainerTransitionType.fade,
                      openColor: Colors.white,
                      closedColor: Colors.white,
                      closedElevation: 0,
                      openElevation: 0,
                      closedShape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      onClosed: (_) {
                        isDetailOpen.value = false;
                        _load();
                      },
                      closedBuilder: (context, openContainer) => AnimatedOpacity(
                        opacity: _hiddenMemoId == memo.id ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: MemoCard(
                          clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                          distance: memo.distance != null ? '${memo.distance}yd' : null,
                          bodyText: memo.body,
                          thumbnailPath: _thumbnails[memo.id],
                          margin: EdgeInsets.zero,
                          onTap: () {
                            setState(() => _hiddenMemoId = memo.id);
                            isDetailOpen.value = true;
                            openContainer();
                          },
                        ),
                      ),
                      openBuilder: (context, _) => MemoExpandedCard(
                        memo: memo,
                        clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// 日付ヘッダー（1週間以内は相対表示）
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    if (diff <= 6) return '$diff日前';

    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}（$weekday）';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 24, 8),
      child: Text(
        _label(),
        style: AppTypography.jpSubHeader.copyWith(color: AppColors.textMedium),
      ),
    );
  }
}

// ── お気に入り一覧 ────────────────────────────────────
class _FavoriteMemosTab extends StatefulWidget {
  const _FavoriteMemosTab();

  @override
  State<_FavoriteMemosTab> createState() => _FavoriteMemosTabState();
}

class _FavoriteMemosTabState extends State<_FavoriteMemosTab> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();
  final _mediaRepo = MediaRepository();
  int? _hiddenMemoId;

  List<PracticeMemo> _memos = [];
  Map<int, String> _clubNames = {};
  Map<int, String?> _thumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memos = await _memoRepo.getFavoriteMemos();
    final clubs = await _clubRepo.getActiveClubs();

    final mediaResults = await Future.wait(
      memos.map((m) => m.id != null
          ? _mediaRepo.getMediaByMemoId(m.id!)
          : Future.value([])),
    );

    final docsDir = await getApplicationDocumentsDirectory();
    final thumbnails = <int, String?>{};
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      if (memo.id != null && mediaResults[i].isNotEmpty) {
        final first = mediaResults[i].first;
        final rawPath = first.isVideo ? first.thumbnailUri : first.uri;
        if (rawPath != null) {
          thumbnails[memo.id!] = MediaPathHelper.resolve(rawPath, docsDir.path);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _thumbnails = thumbnails;
      _isLoading = false;
      _hiddenMemoId = null;
    });
  }

  Future<void> _toggleFavorite(PracticeMemo memo) async {
    if (memo.id == null) return;
    await _memoRepo.toggleFavorite(memo.id!, !memo.isFavorite);
    await _load();
  }

  List<_DateGroup> get _grouped {
    final map = <String, _DateGroup>{};
    final order = <String>[];
    for (final memo in _memos) {
      final dt = memo.practicedAt;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (!map.containsKey(key)) {
        map[key] = _DateGroup(dt, []);
        order.add(key);
      }
      map[key]!.memos.add(memo);
    }
    return order.map((k) => map[k]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_memos.isEmpty) {
      return Center(
        child: Text(
          'お気に入りはまだありません',
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final groups = _grouped;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 24, bottom: 80),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(date: group.date),
              ...group.memos.map((memo) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OpenContainer<bool>(
                      transitionDuration: const Duration(milliseconds: 400),
                      transitionType: ContainerTransitionType.fade,
                      openColor: Colors.white,
                      closedColor: Colors.white,
                      closedElevation: 0,
                      openElevation: 0,
                      closedShape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      onClosed: (_) {
                        isDetailOpen.value = false;
                        _load();
                      },
                      closedBuilder: (context, openContainer) => AnimatedOpacity(
                        opacity: _hiddenMemoId == memo.id ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: MemoCard(
                          clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                          distance: memo.distance != null ? '${memo.distance}yd' : null,
                          bodyText: memo.body,
                          thumbnailPath: _thumbnails[memo.id],
                          margin: EdgeInsets.zero,
                          onTap: () {
                            setState(() => _hiddenMemoId = memo.id);
                            isDetailOpen.value = true;
                            openContainer();
                          },
                        ),
                      ),
                      openBuilder: (context, _) => MemoExpandedCard(
                        memo: memo,
                        clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
