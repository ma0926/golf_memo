import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/memo_card.dart';
import '../memo_detail/memo_detail_screen.dart';
import '../../app.dart' show isDetailOpen;

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
          title: const Text(
            'メモ一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Hiragino Sans',
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Image.asset('assets/icons/settings.png', width: 28, height: 28),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: Image.asset('assets/icons/search.png', width: 28, height: 28),
              onPressed: () => context.push('/search'),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 2.0),
              borderRadius: BorderRadius.zero,
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Color(0xFF4B5E96),
            dividerHeight: 0.3,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Hiragino Sans',
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Hiragino Sans',
            ),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memos = await _memoRepo.getAllMemos();
    final clubs = await _clubRepo.getActiveClubs();

    final mediaResults = await Future.wait(
      memos.map((m) => m.id != null
          ? _mediaRepo.getMediaByMemoId(m.id!)
          : Future.value([])),
    );

    final thumbnails = <int, String?>{};
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      if (memo.id != null && mediaResults[i].isNotEmpty) {
        final first = mediaResults[i].first;
        thumbnails[memo.id!] = first.isVideo ? first.thumbnailUri : first.uri;
      }
    }

    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _thumbnails = thumbnails;
      _isLoading = false;
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
      return const Center(
        child: Text(
          'まだ記録がありません\n＋ボタンから追加しましょう',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.8),
        ),
      );
    }

    final groups = _grouped;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
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
                      },
                      closedBuilder: (context, openContainer) => MemoCard(
                        clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                        distance: memo.distance != null ? '${memo.distance}yd' : null,
                        bodyText: memo.body,
                        thumbnailPath: _thumbnails[memo.id],
                        isFavorite: memo.isFavorite,
                        margin: EdgeInsets.zero,
                        onTap: () {
                          isDetailOpen.value = true;
                          openContainer();
                        },
                        onToggleFavorite: () => _toggleFavorite(memo),
                      ),
                      openBuilder: (context, _) =>
                          MemoDetailScreen(memoId: memo.id!),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

// 日付ヘッダー（例: "1/12  金  2026"）
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${date.month}/${date.day}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
              height: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                weekday,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${date.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
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

    final thumbnails = <int, String?>{};
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      if (memo.id != null && mediaResults[i].isNotEmpty) {
        final first = mediaResults[i].first;
        thumbnails[memo.id!] = first.isVideo ? first.thumbnailUri : first.uri;
      }
    }

    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _thumbnails = thumbnails;
      _isLoading = false;
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
      return const Center(
        child: Text(
          'お気に入りはまだありません',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final groups = _grouped;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
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
                      },
                      closedBuilder: (context, openContainer) => MemoCard(
                        clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                        distance: memo.distance != null ? '${memo.distance}yd' : null,
                        bodyText: memo.body,
                        thumbnailPath: _thumbnails[memo.id],
                        isFavorite: memo.isFavorite,
                        margin: EdgeInsets.zero,
                        onTap: () {
                          isDetailOpen.value = true;
                          openContainer();
                        },
                        onToggleFavorite: () => _toggleFavorite(memo),
                      ),
                      openBuilder: (context, _) =>
                          MemoDetailScreen(memoId: memo.id!),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
