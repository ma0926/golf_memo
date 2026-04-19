import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _ReportScreenState extends State<ReportScreen> {
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
    _init();
    memoCreatedNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'レポート',
                style: AppTypography.jpHeader1.copyWith(color: AppColors.textPrimary),
              ),
            ),
            // 期間タブ
            AppTabBar(
              labels: const ['1ヶ月', '6ヶ月'],
              selectedIndex: _periodDays == 30 ? 0 : 1,
              onChanged: (i) {
                setState(() {
                  _periodDays = i == 0 ? 30 : 180;
                  _isLoading = true;
                });
                _loadData();
              },
            ),
            // コンテンツ
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
      return Center(
        child: Text(
          '設定からクラブをONにしてください',
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        // セクション1: クラブ別平均飛距離テーブル
        _SectionTitle(title: 'クラブ別平均飛距離'),
        const SizedBox(height: 12),
        _ClubDistanceTable(
          clubs: _clubs,
          avgDistances: _clubAvgDistances,
        ),
        const SizedBox(height: 32),
        // セクション2: 飛距離の推移
        Row(
          children: [
            _SectionTitle(title: '飛距離の推移'),
            const Spacer(),
            GestureDetector(
              onTap: _showClubSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedClub?.name ?? '—',
                      style: AppTypography.jpSMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // グラフカード
        _DistanceChartCard(
          selectedClub: _selectedClub,
          chartData: _chartData,
          selectedIdx: _selectedIdx,
          docsPath: _docsPath,
          onTapped: (i) => setState(() => _selectedIdx = i),
          onDetailTap: (id) => context.push('/memo/$id'),
        ),
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
            'この期間のデータがありません',
            style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final club = entry.value;
          final avg = avgDistances[club.id]!;
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        club.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.enMMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${avg.round()}y',
                      style: AppTypography.enMMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFF2F3F5)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── グラフカード（タイトル＋チャート＋詳細） ──────────
class _DistanceChartCard extends StatelessWidget {
  final Club? selectedClub;
  final List<_DayData> chartData;
  final int? selectedIdx;
  final String docsPath;
  final ValueChanged<int> onTapped;
  final ValueChanged<int> onDetailTap;

  const _DistanceChartCard({
    required this.selectedClub,
    required this.chartData,
    required this.selectedIdx,
    required this.docsPath,
    required this.onTapped,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // クラブ名タイトル
          Text(
            selectedClub?.name ?? '—',
            style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          // グラフ
          if (chartData.isNotEmpty)
            SizedBox(
              height: 192,
              child: _DistanceChart(
                data: chartData,
                selectedIndex: selectedIdx,
                onTapped: onTapped,
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'この期間の飛距離データがありません',
                  style: AppTypography.jpSRegular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          // 詳細セクション
          if (selectedIdx != null && chartData.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF2F3F5)),
            const SizedBox(height: 16),
            _ChartDetailSection(
              dayData: chartData[selectedIdx!],
              docsPath: docsPath,
              onDetailTap: onDetailTap,
            ),
          ],
        ],
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
    return '${dt.year}年${dt.month}月${dt.day}日 ${w}曜日';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付 + 平均飛距離
        Row(
          children: [
            Text(
              _formatDate(dayData.date),
              style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${dayData.avgDistance.round()}yd',
              style: AppTypography.jpHeader2.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        // メモ一覧
        ...dayData.memos.map((memo) => _MemoDetailRow(
              memo: memo,
              docsPath: docsPath,
              onDetailTap: onDetailTap,
            )),
      ],
    );
  }
}

// ── メモ詳細行 ────────────────────────────────────────
class _MemoDetailRow extends StatefulWidget {
  final PracticeMemo memo;
  final String docsPath;
  final ValueChanged<int> onDetailTap;

  const _MemoDetailRow({
    required this.memo,
    required this.docsPath,
    required this.onDetailTap,
  });

  @override
  State<_MemoDetailRow> createState() => _MemoDetailRowState();
}

class _MemoDetailRowState extends State<_MemoDetailRow> {
  final _mediaRepo = MediaRepository();
  Media? _firstMedia;
  bool _mediaLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (widget.memo.id == null) return;
    final mediaList = await _mediaRepo.getMediaByMemoId(widget.memo.id!);
    if (!mounted) return;
    setState(() {
      _firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
      _mediaLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memo = widget.memo;
    final hasThumbnail = _mediaLoaded && _firstMedia != null;
    final thumbPath = hasThumbnail
        ? MediaPathHelper.resolve(
            _firstMedia!.thumbnailUri ?? _firstMedia!.uri,
            widget.docsPath,
          )
        : null;

    return GestureDetector(
      onTap: memo.id != null ? () => widget.onDetailTap(memo.id!) : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // メモ本文 + サムネイル
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // テキスト
                Expanded(
                  child: memo.body != null && memo.body!.isNotEmpty
                      ? Text(
                          memo.body!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.jpMRegular.copyWith(
                            color: AppColors.textMedium,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // サムネイル
                if (hasThumbnail && thumbPath != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(thumbPath),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 72, height: 72),
                    ),
                  ),
                ],
              ],
            ),
            // タグ行
            if (memo.shotShape != null || memo.condition != null || memo.wind != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (memo.shotShape != null) ...[
                    _TagItem(
                      iconPath: 'assets/icons/${memo.shotShape}.svg',
                      label: AppConstants.shotShapeLabels[memo.shotShape] ?? memo.shotShape!,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (memo.condition != null) ...[
                    _TagItem(
                      iconPath: AppConstants.conditionIcons[memo.condition]!,
                      label: AppConstants.conditionLabels[memo.condition] ?? memo.condition!,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (memo.wind != null)
                    _TagItem(
                      iconPath: AppConstants.windIcons[memo.wind]!,
                      label: AppConstants.windLabels[memo.wind] ?? memo.wind!,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagItem extends StatelessWidget {
  final String iconPath;
  final String label;

  const _TagItem({required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14,
          height: 14,
          colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary),
        ),
      ],
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
        clipData: const FlClipData.all(),
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
                final isSelected = index == selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 3,
                  color: isSelected ? AppColors.accent : Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.accent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withAlpha(20),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}y',
                  style: AppTypography.enSMedium100.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
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
                    style: AppTypography.enSMedium100.copyWith(
                      color: AppColors.textPlaceholder,
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
            left: BorderSide(color: AppColors.divider, width: 1),
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
  final ScrollController scrollController;

  const _ClubSelectSheet({
    required this.clubs,
    required this.scrollController,
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
        color: Colors.white,
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
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry.key,
                            style: AppTypography.jpHeader4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...entry.value.map((club) => AppListTile(
                          title: club.name,
                          trailing: club.id == selectedClubId
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, club),
                        )),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
