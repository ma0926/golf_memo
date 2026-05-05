import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/memo_card.dart';
import 'memo_expanded_card.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/media_path_helper.dart';
import '../../app.dart' show isDetailOpen, memoCreatedNotifier;

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
          toolbarHeight: 48,
          titleSpacing: 16,
          title: Text(
            'My GOLF',
            style: AppTypography.enHeader1.copyWith(
              color: const Color(0xFF23264E),
              wordSpacing: 6,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 2.0),
              borderRadius: BorderRadius.zero,
              insets: EdgeInsets.zero,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            labelStyle: AppTypography.jpHeader4,
            unselectedLabelStyle: AppTypography.jpHeader4,
            tabs: const [
              SizedBox(width: 120, height: 38, child: Center(child: Text('すべて'))),
              SizedBox(width: 120, height: 38, child: Center(child: Text('お気に入り'))),
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
  Map<int, String> _clubCategories = {};
  Map<int, bool> _clubIsCustom = {};
  Map<int, List<Media>> _memoMediaList = {};
  String _docsPath = '';
  bool _isLoading = true;
  int? _hiddenMemoId;

  late final Future<String> _docsDirFuture = _initDocsPath();

  Future<String> _initDocsPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      return '';
    }
  }

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
    try {
      final memos = await _memoRepo.getAllMemos();
      final clubs = await _clubRepo.getActiveClubs();

      final mediaResults = await Future.wait(
        memos.map((m) => m.id != null
            ? _mediaRepo.getMediaByMemoId(m.id!)
            : Future.value(<Media>[])),
      );

      final docsPath = await _docsDirFuture;
      final memoMediaMap = <int, List<Media>>{};
      for (var i = 0; i < memos.length; i++) {
        if (memos[i].id != null) memoMediaMap[memos[i].id!] = mediaResults[i];
      }

      if (!mounted) return;
      setState(() {
        _memos = memos;
        _clubNames = {for (final c in clubs) c.id!: c.name};
        _clubCategories = {for (final c in clubs) c.id!: c.category};
        _clubIsCustom = {for (final c in clubs) c.id!: c.isCustom};
        _memoMediaList = memoMediaMap;
        _docsPath = docsPath;
        _isLoading = false;
        _hiddenMemoId = null;
      });
    } catch (e, st) {
      debugPrint('_AllMemosTab _load error: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MemoMediaItem> _buildMediaItems(int? memoId) {
    final list = _memoMediaList[memoId];
    if (list == null || list.isEmpty) return [];
    return list.take(4).map((m) {
      final rawDisplay = m.isVideo ? m.thumbnailUri : m.uri;
      final rawVideo = m.isVideo ? m.uri : null;
      return (
        displayPath: rawDisplay != null ? MediaPathHelper.resolve(rawDisplay, _docsPath) : '',
        isVideo: m.isVideo,
        videoPath: rawVideo != null ? MediaPathHelper.resolve(rawVideo, _docsPath) : null,
      );
    }).toList();
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
              ...group.memos.map((memo) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
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
                          clubCategory: _clubCategories[memo.clubId],
                          clubIsCustom: _clubIsCustom[memo.clubId] ?? false,
                          mediaItems: _buildMediaItems(memo.id),
                          distance: memo.distance != null ? '${memo.distance}yd' : null,
                          shotShape: memo.shotShape,
                          condition: memo.condition,
                          wind: memo.wind,
                          bodyText: memo.body,
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
                        clubCategory: _clubCategories[memo.clubId],
                        clubIsCustom: _clubIsCustom[memo.clubId] ?? false,
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
    return '${date.month}月${date.day}日 ${weekday}曜日';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 24, 8),
      child: Text(
        _label(),
        style: AppTypography.jpHeader4.copyWith(color: AppColors.textMedium),
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
  Map<int, String> _clubCategories = {};
  Map<int, bool> _clubIsCustom = {};
  Map<int, List<Media>> _memoMediaList = {};
  String _docsPath = '';
  bool _isLoading = true;

  late final Future<String> _docsDirFuture = _initDocsPath();

  Future<String> _initDocsPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final memos = await _memoRepo.getFavoriteMemos();
      final clubs = await _clubRepo.getActiveClubs();

      final mediaResults = await Future.wait(
        memos.map((m) => m.id != null
            ? _mediaRepo.getMediaByMemoId(m.id!)
            : Future.value(<Media>[])),
      );

      final docsPath = await _docsDirFuture;
      final memoMediaMap = <int, List<Media>>{};
      for (var i = 0; i < memos.length; i++) {
        if (memos[i].id != null) memoMediaMap[memos[i].id!] = mediaResults[i];
      }

      if (!mounted) return;
      setState(() {
        _memos = memos;
        _clubNames = {for (final c in clubs) c.id!: c.name};
        _clubCategories = {for (final c in clubs) c.id!: c.category};
        _clubIsCustom = {for (final c in clubs) c.id!: c.isCustom};
        _memoMediaList = memoMediaMap;
        _docsPath = docsPath;
        _isLoading = false;
        _hiddenMemoId = null;
      });
    } catch (e, st) {
      debugPrint('_FavoriteMemosTab _load error: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MemoMediaItem> _buildMediaItems(int? memoId) {
    final list = _memoMediaList[memoId];
    if (list == null || list.isEmpty) return [];
    return list.take(4).map((m) {
      final rawDisplay = m.isVideo ? m.thumbnailUri : m.uri;
      final rawVideo = m.isVideo ? m.uri : null;
      return (
        displayPath: rawDisplay != null ? MediaPathHelper.resolve(rawDisplay, _docsPath) : '',
        isVideo: m.isVideo,
        videoPath: rawVideo != null ? MediaPathHelper.resolve(rawVideo, _docsPath) : null,
      );
    }).toList();
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
              ...group.memos.map((memo) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
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
                          clubCategory: _clubCategories[memo.clubId],
                          clubIsCustom: _clubIsCustom[memo.clubId] ?? false,
                          mediaItems: _buildMediaItems(memo.id),
                          distance: memo.distance != null ? '${memo.distance}yd' : null,
                          shotShape: memo.shotShape,
                          condition: memo.condition,
                          wind: memo.wind,
                          bodyText: memo.body,
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
                        clubCategory: _clubCategories[memo.clubId],
                        clubIsCustom: _clubIsCustom[memo.clubId] ?? false,
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
