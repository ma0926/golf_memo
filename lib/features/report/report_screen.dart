import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/media_path_helper.dart';
import '../../data/models/club.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../app.dart' show memoCreatedNotifier;
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_section_title.dart';
import '../../shared/widgets/memo_card.dart' show ClubBadge;
import '../../shared/widgets/app_tab_bar.dart';
import '../../shared/widgets/sheet_drag_handle.dart';

// ── 1日分のデータ ─────────────────────────────────────
class _DayData {
  final DateTime date;
  final double avgDistance;
  final List<PracticeMemo> memos;

  const _DayData({
    required this.date,
    required this.avgDistance,
    required this.memos,
  });
}

// ── レポート画面 ──────────────────────────────────────
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();

  List<Club> _clubs = [];
  Club? _selectedClub;
  int _periodDays = 30;

  List<_DayData> _chartData = [];
  int? _selectedIdx;
  Map<int, double> _clubAvgDistances = {};

  bool _isLoading = true;
  String _docsPath = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _periodDays = _tabController.index == 0 ? 30 : 60;
        _isLoading = true;
      });
      _loadData();
    });
    _init();
    memoCreatedNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    memoCreatedNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _docsPath = dir.path;
    await _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveOnClubs();
    if (!mounted) return;
    setState(() {
      _clubs = clubs;
      _selectedClub = clubs.isNotEmpty ? clubs.first : null;
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final now = DateTime.now();
    final from = now.subtract(Duration(days: _periodDays));

    // 期間内の全メモを一括取得
    final allMemos = await _memoRepo.getMemosByDateRange(from: from, to: now);
    if (!mounted) return;

    // クラブ別平均飛距離を集計
    final distByClub = <int, List<int>>{};
    for (final m in allMemos) {
      if (m.distance != null) {
        distByClub.putIfAbsent(m.clubId, () => []).add(m.distance!);
      }
    }
    final avgMap = distByClub.map(
      (k, v) => MapEntry(k, v.fold<int>(0, (a, b) => a + b) / v.length),
    );

    // 選択クラブのグラフデータ
    final clubMemos = _selectedClub != null
        ? allMemos.where((m) => m.clubId == _selectedClub!.id).toList()
        : <PracticeMemo>[];
    final chart = _buildChartData(clubMemos);

    setState(() {
      _clubAvgDistances = avgMap;
      _chartData = chart;
      _selectedIdx = chart.isNotEmpty ? chart.length - 1 : null;
      _isLoading = false;
    });
  }

  List<_DayData> _buildChartData(List<PracticeMemo> memos) {
    final grouped = <DateTime, List<PracticeMemo>>{};
    for (final m in memos) {
      if (m.distance == null) continue;
      final day = DateTime(m.practicedAt.year, m.practicedAt.month, m.practicedAt.day);
      grouped.putIfAbsent(day, () => []).add(m);
    }
    final result = grouped.entries.map((e) {
      final avg = e.value.fold<int>(0, (acc, m) => acc + m.distance!) / e.value.length;
      return _DayData(date: e.key, avgDistance: avg, memos: e.value);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<void> _showClubSheet() async {
    final selected = await showModalBottomSheet<Club>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _ClubSelectSheet(
          clubs: _clubs,
          selectedClubId: _selectedClub?.id,
          availableClubIds: _clubAvgDistances.keys.toSet(),
          scrollController: scrollController,
        ),
      ),
    );
    if (selected != null && selected.id != _selectedClub?.id) {
      setState(() {
        _selectedClub = selected;
        _isLoading = true;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'レポート',
          style: AppTypography.jpHeader1.copyWith(color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.textPrimary, width: 2.0),
            borderRadius: BorderRadius.zero,
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppColors.primaryMiddle,
          dividerHeight: 0.3,
          labelStyle: AppTypography.jpHeader4,
          unselectedLabelStyle: AppTypography.jpHeader4,
          tabs: const [
            Tab(text: '30日', height: 38),
            Tab(text: '60日', height: 38),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_clubs.isEmpty) {
      return Center(
        child: Text(
          '設定からクラブをONにしてください',
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 100),
      children: [
        // セクション1: クラブ別平均飛距離テーブル
        _ClubDistanceTable(
          clubs: _clubs,
          avgDistances: _clubAvgDistances,
        ),
        const SizedBox(height: 16),
        // セクション2タイトル
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '飛距離の推移',
                style: AppTypography.jpHeader3.copyWith(color: AppColors.textMedium),
              ),
              GestureDetector(
                onTap: _showClubSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderHigh),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          _selectedClub?.name ?? '—',
                          style: AppTypography.jpSMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
        // グラフカード
        _DistanceChartCard(
          chartData: _chartData,
          selectedIdx: _selectedIdx,
          onTapped: (i) => setState(() => _selectedIdx = i),
        ),
        // 選択時のメモ概要カード
        if (_selectedIdx != null && _chartData.isNotEmpty) ...[
          const SizedBox(height: 2),
          _MemoSummaryCard(
            dayData: _chartData[_selectedIdx!],
            selectedClub: _selectedClub,
            onDetailTap: (id) => context.push('/memo/$id'),
          ),
        ],
      ],
    );
  }
}

// ── セクションタイトル ────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.jpHeader3.copyWith(color: AppColors.textMedium),
    );
  }
}

// ── クラブ別平均飛距離テーブル ─────────────────────────
class _ClubDistanceTable extends StatelessWidget {
  final List<Club> clubs;
  final Map<int, double> avgDistances;

  const _ClubDistanceTable({
    required this.clubs,
    required this.avgDistances,
  });

  @override
  Widget build(BuildContext context) {
    final rows = clubs
        .where((c) => avgDistances.containsKey(c.id))
        .toList();

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2F3F5)),
        ),
        child: Center(
          child: Text(
            'データがありません',
            style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'クラブ別平均飛距離',
                style: AppTypography.jpHeader3.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
        ...rows.map((club) {
          final avg = avgDistances[club.id]!;
          final parenIdx = club.name.indexOf('（');
          final hasSubtitle = parenIdx != -1;
          final mainName = hasSubtitle ? club.name.substring(0, parenIdx) : club.name;
          final subName = hasSubtitle ? club.name.substring(parenIdx) : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClubBadge(name: club.name, category: club.category, isCustom: club.isCustom),
                  const SizedBox(width: 12),
                  Expanded(
                    child: hasSubtitle
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                              Text(subName, style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary)),
                            ],
                          )
                        : Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${avg.round()}yd',
                    style: AppTypography.enHeader4.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── グラフカード（タイトル＋チャート＋詳細） ──────────
class _DistanceChartCard extends StatelessWidget {
  final List<_DayData> chartData;
  final int? selectedIdx;
  final ValueChanged<int> onTapped;

  const _DistanceChartCard({
    required this.chartData,
    required this.selectedIdx,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: chartData.isNotEmpty
          ? SizedBox(
              height: 192,
              child: _DistanceChart(
                data: chartData,
                selectedIndex: selectedIdx,
                onTapped: onTapped,
              ),
            )
          : const SizedBox(
              height: 120,
              child: Center(child: Text('データがありません')),
            ),
    );
  }
}

// ── メモ概要カード ────────────────────────────────────
class _MemoSummaryCard extends StatelessWidget {
  final _DayData dayData;
  final Club? selectedClub;
  final ValueChanged<int> onDetailTap;

  const _MemoSummaryCard({
    required this.dayData,
    required this.selectedClub,
    required this.onDetailTap,
  });

  String _formatDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.year}年${dt.month}月${dt.day}日 ${w}曜日';
  }

  @override
  Widget build(BuildContext context) {
    final memo = dayData.memos.first;
    final hasMeta = memo.shotShape != null || memo.condition != null || memo.wind != null;

    return GestureDetector(
      onTap: memo.id != null ? () => onDetailTap(memo.id!) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClubBadge(
                  name: selectedClub?.name ?? '',
                  category: selectedClub?.category,
                  isCustom: selectedClub?.isCustom ?? false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(dayData.date),
                        style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        selectedClub?.name ?? '',
                        style: AppTypography.jpSMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${dayData.avgDistance.round()}yd',
                  style: AppTypography.enHeader4.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            if (hasMeta) ...[
              const SizedBox(height: 8),
              _ReportMetaRow(
                shotShape: memo.shotShape,
                condition: memo.condition,
                wind: memo.wind,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── グラフ詳細セクション ─────────────────────────────
class _ChartDetailSection extends StatelessWidget {
  final _DayData dayData;
  final String docsPath;
  final ValueChanged<int> onDetailTap;

  const _ChartDetailSection({
    required this.dayData,
    required this.docsPath,
    required this.onDetailTap,
  });

  String _formatDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.month}月${dt.day}日 ${w}曜日';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付 + 飛距離
        Row(
          children: [
            Text(
              _formatDate(dayData.date),
              style: AppTypography.jpSRegular.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text(
              '${dayData.avgDistance.round()}yd',
              style: AppTypography.enMMedium.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        // メタ情報（最初の1件のみ）
        Builder(builder: (_) {
          final first = dayData.memos.firstWhere(
            (m) => m.shotShape != null || m.condition != null || m.wind != null,
            orElse: () => dayData.memos.first,
          );
          return _MemoDetailRow(memo: first, onDetailTap: onDetailTap);
        }),
      ],
    );
  }
}

// ── メモ詳細行 ────────────────────────────────────────
class _MemoDetailRow extends StatelessWidget {
  final PracticeMemo memo;
  final ValueChanged<int> onDetailTap;

  const _MemoDetailRow({
    required this.memo,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeta = memo.shotShape != null || memo.condition != null || memo.wind != null;
    if (!hasMeta) return const SizedBox.shrink();

    return GestureDetector(
      onTap: memo.id != null ? () => onDetailTap(memo.id!) : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _ReportMetaRow(
          shotShape: memo.shotShape,
          condition: memo.condition,
          wind: memo.wind,
        ),
      ),
    );
  }
}

// ── メタ情報行（MemoCard._MemoMetaRow と同スタイル）─────
class _ReportMetaRow extends StatelessWidget {
  final String? shotShape;
  final String? condition;
  final String? wind;

  const _ReportMetaRow({this.shotShape, this.condition, this.wind});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (shotShape != null)
          _MetaChip(label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!),
        if (condition != null)
          _MetaChip(label: AppConstants.conditionLabels[condition] ?? condition!),
        if (wind != null)
          _MetaChip(label: '風${AppConstants.windLabels[wind] ?? wind!}'),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundMiddle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.jpSMedium.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();


// ── 飛距離折れ線グラフ ────────────────────────────────
class _DistanceChart extends StatelessWidget {
  final List<_DayData> data;
  final int? selectedIndex;
  final ValueChanged<int> onTapped;

  const _DistanceChart({
    required this.data,
    required this.selectedIndex,
    required this.onTapped,
  });

  Set<int> _visibleLabelIndices(int n) {
    if (n <= 5) return Set.from(List.generate(n, (i) => i));
    final result = <int>{0, n - 1};
    final step = (n - 1) / 4.0;
    for (int i = 1; i <= 3; i++) {
      result.add((i * step).round());
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgDistance))
        .toList();

    final distances = data.map((d) => d.avgDistance).toList();
    final minDist = distances.reduce((a, b) => a < b ? a : b);
    final maxDist = distances.reduce((a, b) => a > b ? a : b);
    // データ範囲に応じたバッファを加算してY軸レンジを計算
    const buf = 20.0;
    final minY = ((minDist - buf) / 10).floorToDouble() * 10;
    final maxY = ((maxDist + buf) / 10).ceilToDouble() * 10;
    // Y軸グリッド間隔：レンジを3〜4分割した切りの良い値
    final rawInterval = (maxY - minY) / 3;
    final yInterval = (rawInterval / 10).ceilToDouble() * 10;

    final visibleIdx = _visibleLabelIndices(data.length);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (!event.isInterestedForInteractions) return;
            final spots = response?.lineBarSpots;
            if (spots != null && spots.isNotEmpty) {
              onTapped(spots.first.spotIndex);
            }
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                const FlLine(color: Colors.transparent, strokeWidth: 0),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.accent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: data.length > 2,
            curveSmoothness: 0.3,
            color: AppColors.accent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == selectedIndex) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.accent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB1D9F4),       // #B1D9F4
                  Color(0x08EBF2F8),       // rgba(235,242,248,0.03)
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${value.toInt()}y',
                    softWrap: false,
                    style: AppTypography.enSMedium100.copyWith(
                      fontSize: 11,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (value != index.toDouble()) return const SizedBox.shrink();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                if (!visibleIdx.contains(index)) return const SizedBox.shrink();
                final date = data[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: AppTypography.enSMedium100.copyWith(
                      fontSize: 11,
                      color: AppColors.textMedium,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF2F3F5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
      ),
    );
  }
}

// ── クラブ選択シート ──────────────────────────────────
class _ClubSelectSheet extends StatelessWidget {
  final List<Club> clubs;
  final int? selectedClubId;
  final Set<int> availableClubIds;
  final ScrollController scrollController;

  const _ClubSelectSheet({
    required this.clubs,
    required this.scrollController,
    required this.availableClubIds,
    this.selectedClubId,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Club>>{};
    for (final cat in AppConstants.clubCategories) {
      final list = clubs.where((c) => c.category == cat).toList();
      if (list.isNotEmpty) grouped[cat] = list;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SheetDragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'クラブを選択',
                    textAlign: TextAlign.center,
                    style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final entry in grouped.entries) ...[
                    AppSectionTitle(title: entry.key),
                    ...entry.value.map((club) {
                      final parenIdx = club.name.indexOf('（');
                      final hasSubtitle = parenIdx != -1;
                      final mainName = hasSubtitle ? club.name.substring(0, parenIdx) : club.name;
                      final subName = hasSubtitle ? club.name.substring(parenIdx) : '';
                      final hasData = availableClubIds.contains(club.id);
                      final textColor = hasData ? AppColors.textPrimary : AppColors.textPlaceholder;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          minTileHeight: 56,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: ClubBadge(name: club.name, category: club.category, isCustom: club.isCustom),
                          title: hasSubtitle
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: textColor)),
                                    Text(subName, style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary)),
                                  ],
                                )
                              : Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: textColor)),
                          trailing: club.id == selectedClubId
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: hasData ? () => Navigator.pop(context, club) : null,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
