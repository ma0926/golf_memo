import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/memo_card.dart';

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: const Text(
            'メモ一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.primary),
              onPressed: () => context.push('/search'),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'すべて'),
              Tab(text: 'お気に入り'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AllMemosTab(),
            _FavoriteMemosTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/memo/create'),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
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
                  icon: const Icon(Icons.list_alt_outlined),
                  color: AppColors.primary,
                  onPressed: () {},
                ),
                const SizedBox(width: 48),
                IconButton(
                  icon: const Icon(Icons.trending_up_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () => context.push('/report'),
                ),
              ],
            ),
          ),
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

  List<PracticeMemo> _memos = [];
  Map<int, String> _clubNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memos = await _memoRepo.getAllMemos();
    final clubs = await _clubRepo.getActiveClubs();
    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _isLoading = false;
    });
  }

  String _dateKey(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.month}/${dt.day}  $w  ${dt.year}';
  }

  List<MapEntry<String, List<PracticeMemo>>> get _grouped {
    final map = <String, List<PracticeMemo>>{};
    for (final memo in _memos) {
      final key = _dateKey(memo.practicedAt);
      map.putIfAbsent(key, () => []).add(memo);
    }
    return map.entries.toList();
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
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final key = groups[i].key;
          final memos = groups[i].value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...memos.map((memo) => MemoCard(
                    clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
                    distance: memo.distance != null ? '${memo.distance}yd' : null,
                    bodyText: memo.body,
                    onTap: () => context.push('/memo/${memo.id}'),
                  )),
              const SizedBox(height: 8),
            ],
          );
        },
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

  List<PracticeMemo> _memos = [];
  Map<int, String> _clubNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memos = await _memoRepo.getFavoriteMemos();
    final clubs = await _clubRepo.getActiveClubs();
    setState(() {
      _memos = memos;
      _clubNames = {for (final c in clubs) c.id!: c.name};
      _isLoading = false;
    });
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.year}/${dt.month}/${dt.day}（$w）';
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: _memos.length,
        itemBuilder: (context, index) {
          final memo = _memos[index];
          return _FavoriteMemoCard(
            date: _formatDate(memo.practicedAt),
            clubName: _clubNames[memo.clubId] ?? '不明なクラブ',
            distance: memo.distance != null ? '${memo.distance}yd' : null,
            bodyText: memo.body,
            onTap: () => context.push('/memo/${memo.id}'),
          );
        },
      ),
    );
  }
}

// お気に入りタブ用カード
class _FavoriteMemoCard extends StatelessWidget {
  final String date;
  final String clubName;
  final String? distance;
  final String? bodyText;
  final VoidCallback onTap;

  const _FavoriteMemoCard({
    required this.date,
    required this.clubName,
    this.distance,
    this.bodyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  clubName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                if (distance != null)
                  Text(
                    distance!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
              ],
            ),
            if (bodyText != null) ...[
              const SizedBox(height: 4),
              Text(
                bodyText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
