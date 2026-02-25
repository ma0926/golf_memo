import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';

// ── 1日分のデータ ─────────────────────────────────────
class _DayData {
  final DateTime date;
  final double avgDistance; // 複数メモがある日は平均値
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

class _ReportScreenState extends State<ReportScreen> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();

  List<Club> _clubs = [];
  Club? _selectedClub;
  int _periodDays = 30;

  List<_DayData> _chartData = [];   // 飛距離あり・日別集計（グラフ用）
  int? _selectedIdx;                // タップして選択中のグラフ点インデックス

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveOnClubs();
    if (!mounted) return;
    setState(() {
      _clubs = clubs;
      _selectedClub = clubs.isNotEmpty ? clubs.first : null;
    });
    await _loadMemos();
  }

  Future<void> _loadMemos() async {
    if (_selectedClub == null) {
      if (mounted) setState(() { _chartData = []; _selectedIdx = null; _isLoading = false; });
      return;
    }
    final now = DateTime.now();
    final from = now.subtract(Duration(days: _periodDays));
    final memos = await _memoRepo.getMemosByDateRange(
      from: from,
      to: now,
      clubId: _selectedClub!.id,
    );
    if (!mounted) return;
    final chart = _buildChartData(memos);
    setState(() {
      _chartData = chart;
      // 最新の点（末尾）をデフォルト選択
      _selectedIdx = chart.isNotEmpty ? chart.length - 1 : null;
      _isLoading = false;
    });
  }

  // 飛距離ありのメモを日別に集計
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
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  double? get _averageDistance {
    if (_chartData.isEmpty) return null;
    final sum = _chartData.fold<double>(0, (acc, d) => acc + d.avgDistance);
    return sum / _chartData.length;
  }

  Future<void> _showClubSheet() async {
    final selected = await showModalBottomSheet<Club>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClubSelectSheet(clubs: _clubs, selectedClubId: _selectedClub?.id),
    );
    if (selected != null && selected.id != _selectedClub?.id) {
      setState(() { _selectedClub = selected; _isLoading = true; });
      _loadMemos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'レポート',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _PeriodTabs(
              selected: _periodDays,
              onChanged: (days) {
                setState(() { _periodDays = days; _isLoading = true; });
                _loadMemos();
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_clubs.isEmpty) {
      return const Center(
        child: Text('設定からクラブをONにしてください',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final avg = _averageDistance;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // 飛距離ヘッダー + クラブ選択
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Text('飛距離',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: _showClubSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedClub?.name ?? '—',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 平均飛距離
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            avg != null ? '平均: ${avg.round()}yd' : '平均: —',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        // グラフ
        if (_chartData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: SizedBox(
              height: 180,
              child: _DistanceChart(
                data: _chartData,
                selectedIndex: _selectedIdx,
                onTapped: (i) => setState(() => _selectedIdx = i),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('この期間の飛距離データがありません',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          ),
        // タップ時の概要カード
        if (_selectedIdx != null && _chartData.isNotEmpty)
          _DaySummaryCard(
            dayData: _chartData[_selectedIdx!],
            onDetailTap: (id) => context.push('/memo/$id'),
          ),
      ],
    );
  }
}

// ── 期間タブ ──────────────────────────────────────────
class _PeriodTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _Tab(label: '1ヶ月', days: 30, selected: selected, onChanged: onChanged),
          const SizedBox(width: 24),
          _Tab(label: '6ヶ月', days: 180, selected: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int days;
  final int selected;
  final ValueChanged<int> onChanged;

  const _Tab({
    required this.label,
    required this.days,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == days;
    return GestureDetector(
      onTap: () => onChanged(days),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 44,
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

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
    final minY = (minDist / 50).floorToDouble() * 50;
    final maxY = (maxDist / 50).ceilToDouble() * 50 + 50;

    final visibleIdx = _visibleLabelIndices(data.length);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        // タッチ設定
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (!event.isInterestedForInteractions) return;
            final spots = response?.lineBarSpots;
            if (spots != null && spots.isNotEmpty) {
              onTapped(spots.first.spotIndex);
            }
          },
          // タッチ中のスポットインジケーター（縦線なし・ドットのみ）
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                const FlLine(color: Colors.transparent, strokeWidth: 0),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 6,
                    color: Colors.blue,
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
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 3,
                  color: isSelected ? Colors.blue : Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.blue,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(20),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 50,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                  textAlign: TextAlign.right,
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
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.divider,
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── タップした日の概要カード ──────────────────────────
class _DaySummaryCard extends StatelessWidget {
  final _DayData dayData;
  final ValueChanged<int> onDetailTap;

  const _DaySummaryCard({
    required this.dayData,
    required this.onDetailTap,
  });

  String _formatDate(DateTime dt) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[dt.weekday - 1];
    return '${dt.year}年${dt.month}月${dt.day}日（$w）';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  _formatDate(dayData.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayData.avgDistance.round()}yd',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // メモ一覧
          ...dayData.memos.asMap().entries.map((entry) {
            final i = entry.key;
            final memo = entry.value;
            final isLast = i == dayData.memos.length - 1;
            return Column(
              children: [
                _SummaryMemoRow(memo: memo, onDetailTap: onDetailTap),
                if (!isLast) const Divider(height: 1, indent: 14, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryMemoRow extends StatelessWidget {
  final PracticeMemo memo;
  final ValueChanged<int> onDetailTap;

  const _SummaryMemoRow({required this.memo, required this.onDetailTap});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (memo.condition != null)
        AppConstants.conditionLabels[memo.condition] ?? memo.condition!,
      if (memo.shotShape != null)
        AppConstants.shotShapeLabels[memo.shotShape] ?? memo.shotShape!,
      if (memo.wind != null)
        '風: ${AppConstants.windLabels[memo.wind] ?? memo.wind!}',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 本文プレビュー
          if (memo.body != null && memo.body!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                memo.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          // チップ + 詳細ボタン
          Row(
            children: [
              ...chips.map((label) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _Chip(label),
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => onDetailTap(memo.id!),
                child: const Row(
                  children: [
                    Text('詳細',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Icon(Icons.chevron_right,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

// ── クラブ選択シート ──────────────────────────────────
class _ClubSelectSheet extends StatelessWidget {
  final List<Club> clubs;
  final int? selectedClubId;

  const _ClubSelectSheet({required this.clubs, this.selectedClubId});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Club>>{};
    for (final cat in AppConstants.clubCategories) {
      final list = clubs.where((c) => c.category == cat).toList();
      if (list.isNotEmpty) grouped[cat] = list;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('クラブを選択',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    ...entry.value.map((club) => ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(club.name,
                              style: const TextStyle(
                                  fontSize: 15, color: AppColors.textPrimary)),
                          trailing: club.id == selectedClubId
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, club),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
