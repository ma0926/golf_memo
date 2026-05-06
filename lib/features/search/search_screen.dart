import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/media_path_helper.dart';
import '../../data/models/club.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_section_title.dart';
import '../../shared/widgets/memo_card.dart' show MemoCard, MemoMediaItem, ClubBadge;
import '../memo_list/memo_expanded_card.dart';
import '../../shared/widgets/sheet_drag_handle.dart';
import 'package:golf_memo/l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // フィルター状態
  bool _isFavorite = false;
  bool _hasAttachment = false;
  int? _selectedClubId;
  String? _selectedClubName;
  String? _selectedDate;     // 'month1' / 'month6' / 'year1' / null
  int? _distanceMin;
  int? _distanceMax;
  String? _selectedCondition;
  Set<String> _selectedShotShapes = {};

  bool get _hasResults => _searchController.text.isNotEmpty || _hasAnyFilter;

  // 記録日チップのラベル
  String? _dateLabel(AppLocalizations l10n) {
    switch (_selectedDate) {
      case 'month1': return l10n.dateRange1m;
      case 'month6': return l10n.dateRange6m;
      case 'year1':  return l10n.dateRange1y;
      default:       return null;
    }
  }

  // 飛距離チップのラベル
  String? get _distanceLabel {
    if (_distanceMin != null && _distanceMax != null) return '$_distanceMin〜${_distanceMax}yd';
    if (_distanceMin != null) return '${_distanceMin}yd〜';
    if (_distanceMax != null) return '〜${_distanceMax}yd';
    return null;
  }

  // 球筋チップのラベル（複数選択をカンマ区切りで表示）
  String? get _shotShapeLabel {
    if (_selectedShotShapes.isEmpty) return null;
    return _selectedShotShapes
        .map((k) => AppConstants.shotShapeLabels[k] ?? k)
        .join(', ');
  }

  bool get _hasAnyFilter =>
      _isFavorite ||
      _hasAttachment ||
      _selectedClubId != null ||
      _selectedDate != null ||
      _distanceMin != null ||
      _distanceMax != null ||
      _selectedCondition != null ||
      _selectedShotShapes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── フィルターシートを開く ────────────────────────
  void _openClubSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SheetDragHandle(),
              Text(
                AppLocalizations.of(context)!.filterClub,
                textAlign: TextAlign.center,
                style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _ClubFilterContent(
                  scrollController: scrollController,
                  selectedId: _selectedClubId,
                  onApply: (id, name) => setState(() {
                    _selectedClubId = id;
                    _selectedClubName = name;
                  }),
                  onClear: () => setState(() {
                    _selectedClubId = null;
                    _selectedClubName = null;
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDateSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showFilterSheet(
      title: l10n.filterDate,
      child: _DateFilterContent(
        selected: _selectedDate,
        onSelect: (value) {
          setState(() => _selectedDate = value);
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
      showButtons: false,
    );
  }

  void _openDistanceSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showFilterSheet(
      title: l10n.filterDistance,
      child: _DistanceFilterContent(
        min: _distanceMin,
        max: _distanceMax,
        onApply: (min, max) => setState(() {
          _distanceMin = min;
          _distanceMax = max;
        }),
        onClear: () => setState(() {
          _distanceMin = null;
          _distanceMax = null;
        }),
      ),
    );
  }

  void _openConditionSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showFilterSheet(
      title: l10n.filterCondition,
      child: _ConditionFilterContent(
        selected: _selectedCondition,
        onApply: (value) => setState(() => _selectedCondition = value),
        onClear: () => setState(() => _selectedCondition = null),
      ),
    );
  }

  void _openShotShapeSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showFilterSheet(
      title: l10n.filterShotShape,
      showButtons: false,
      child: _ShotShapeFilterContent(
        selected: _selectedShotShapes,
        onApply: (values) => setState(() => _selectedShotShapes = values),
        onClear: () => setState(() => _selectedShotShapes = {}),
      ),
    );
  }

  void _showFilterSheet({
    required String title,
    required Widget child,
    bool showButtons = true,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheetWrapper(
        title: title,
        showButtons: showButtons,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 48,
        centerTitle: true,
        title: Text(
          l10n.navSearch,
          style: AppTypography.jpHeader2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 検索バー
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF2F3F5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 24, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: l10n.placeholderSearch,
                                hintStyle: AppTypography.jpMRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTypography.jpMRegular.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.cancel, size: 16, color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // フィルターチップ（横スクロール）
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: l10n.tabFavorites,
                    isSelected: _isFavorite,
                    isToggle: true,
                    showArrow: false,
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterAttachment,
                    isSelected: _hasAttachment,
                    isToggle: true,
                    showArrow: false,
                    onTap: () => setState(() => _hasAttachment = !_hasAttachment),
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterClub,
                    isSelected: _selectedClubId != null,
                    showArrow: true,
                    selectedLabel: _selectedClubName,
                    onTap: _openClubSheet,
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterDate,
                    isSelected: _selectedDate != null,
                    showArrow: true,
                    selectedLabel: _dateLabel(l10n),
                    onTap: _openDateSheet,
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterDistance,
                    isSelected: _distanceMin != null || _distanceMax != null,
                    showArrow: true,
                    selectedLabel: _distanceLabel,
                    onTap: _openDistanceSheet,
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterShotShape,
                    isSelected: _selectedShotShapes.isNotEmpty,
                    showArrow: true,
                    selectedLabel: _shotShapeLabel,
                    onTap: _openShotShapeSheet,
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: l10n.filterCondition,
                    isSelected: _selectedCondition != null,
                    showArrow: true,
                    selectedLabel: _selectedCondition != null
                        ? AppConstants.conditionLabels[_selectedCondition]
                        : null,
                    onTap: _openConditionSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 検索結果
            Expanded(
              child: _hasResults
                  ? _SearchResultsList(
                      keyword: _searchController.text,
                      isFavorite: _isFavorite,
                      hasAttachment: _hasAttachment,
                      clubId: _selectedClubId,
                      selectedDate: _selectedDate,
                      distanceMin: _distanceMin,
                      distanceMax: _distanceMax,
                      condition: _selectedCondition,
                      shotShapes: _selectedShotShapes,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── フィルターチップ ──────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool showArrow;
  final bool isToggle;
  final String? selectedLabel;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.showArrow,
    required this.onTap,
    this.isToggle = false,
    this.selectedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected;
    final bgColor = isActive ? AppColors.primary : Colors.white;
    final textColor = isActive ? Colors.white : AppColors.textSecondary;
    final borderColor = AppColors.borderHigh;

    final showCheck = isToggle && isSelected;
    final hasTrailingIcon = showCheck || showArrow;
    final displayLabel = (!isToggle && isSelected && selectedLabel != null)
        ? selectedLabel!
        : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 6, hasTrailingIcon ? 8 : 12, 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayLabel,
              style: AppTypography.jpSMedium.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                height: 1,
              ),
            ),
            if (showCheck) ...[
              const SizedBox(width: 4),
              SvgPicture.asset(
                'assets/icons/filter_check.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
            ],
            if (showArrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down, size: 18, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

// ── フィルターシートのラッパー ─────────────────────────
class _FilterSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showButtons;

  const _FilterSheetWrapper({
    required this.title,
    required this.child,
    required this.showButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetDragHandle(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          child,
          if (showButtons) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 検索結果リスト（DBから取得） ──────────────────────
class _SearchResultsList extends StatefulWidget {
  final String keyword;
  final bool isFavorite;
  final bool hasAttachment;
  final int? clubId;
  final String? selectedDate;
  final int? distanceMin;
  final int? distanceMax;
  final String? condition;
  final Set<String> shotShapes;

  const _SearchResultsList({
    required this.keyword,
    required this.isFavorite,
    required this.hasAttachment,
    required this.clubId,
    required this.selectedDate,
    required this.distanceMin,
    required this.distanceMax,
    required this.condition,
    required this.shotShapes,
  });

  @override
  State<_SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<_SearchResultsList> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();
  final _mediaRepo = MediaRepository();

  List<PracticeMemo> _results = [];
  Map<int, String> _clubNames = {};
  Map<int, String> _clubCategories = {};
  Map<int, bool> _clubIsCustom = {};
  Map<int, List<Media>> _memoMediaList = {};
  String _docsPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(_SearchResultsList old) {
    super.didUpdateWidget(old);
    final shotShapesChanged = widget.shotShapes.length != old.shotShapes.length ||
        !widget.shotShapes.containsAll(old.shotShapes);
    if (widget.keyword != old.keyword ||
        widget.isFavorite != old.isFavorite ||
        widget.hasAttachment != old.hasAttachment ||
        widget.clubId != old.clubId ||
        widget.selectedDate != old.selectedDate ||
        widget.distanceMin != old.distanceMin ||
        widget.distanceMax != old.distanceMax ||
        widget.condition != old.condition ||
        shotShapesChanged) {
      _search();
    }
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);

    // 記録日フィルターを日付に変換
    DateTime? practicedBefore;
    final now = DateTime.now();
    switch (widget.selectedDate) {
      case 'month1':
        practicedBefore = now.subtract(const Duration(days: 30));
      case 'month6':
        practicedBefore = now.subtract(const Duration(days: 180));
      case 'year1':
        practicedBefore = now.subtract(const Duration(days: 365));
    }

    final results = await _memoRepo.searchMemos(
      keyword: widget.keyword.isEmpty ? null : widget.keyword,
      isFavorite: widget.isFavorite ? true : null,
      hasAttachment: widget.hasAttachment ? true : null,
      clubId: widget.clubId,
      practicedBefore: practicedBefore,
      distanceMin: widget.distanceMin,
      distanceMax: widget.distanceMax,
      condition: widget.condition,
      shotShapes: widget.shotShapes.isEmpty ? null : widget.shotShapes.toList(),
    );

    // 結果に含まれるクラブ名を一括取得
    final clubMap = <int, String>{};
    if (results.isNotEmpty) {
      final allClubs = await _clubRepo.getActiveClubs();
      for (final c in allClubs) {
        clubMap[c.id!] = c.name;
        _clubCategories[c.id!] = c.category;
        _clubIsCustom[c.id!] = c.isCustom;
      }
      // 削除済みクラブは個別に取得
      for (final memo in results) {
        if (!clubMap.containsKey(memo.clubId)) {
          final club = await _clubRepo.getClubById(memo.clubId);
          if (club != null) clubMap[memo.clubId] = club.name;
        }
      }
    }

    // メディアを読み込む
    final mediaResults = await Future.wait(
      results.map((m) => m.id != null
          ? _mediaRepo.getMediaByMemoId(m.id!)
          : Future.value(<Media>[])),
    );
    final docsDir = await getApplicationDocumentsDirectory();
    final memoMediaMap = <int, List<Media>>{};
    for (var i = 0; i < results.length; i++) {
      if (results[i].id != null) memoMediaMap[results[i].id!] = mediaResults[i];
    }

    if (mounted) {
      setState(() {
        _results = results;
        _clubNames = clubMap;
        _memoMediaList = memoMediaMap;
        _docsPath = docsDir.path;
        _isLoading = false;
      });
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

  String _formatDate(DateTime dt, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final memoDay = DateTime(dt.year, dt.month, dt.day);
    if (memoDay == today) return l10n.dateToday;
    final weekdays = [l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun];
    final w = weekdays[dt.weekday - 1];
    return l10n.dateFull(dt.month, dt.day, w);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.emptySearch,
          style: AppTypography.jpSRegular.copyWith(color: AppColors.textPlaceholder),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final memo = _results[index];
        final clubName = _clubNames[memo.clubId] ?? AppLocalizations.of(context)!.unknownClub;
        final mediaItems = _buildMediaItems(memo.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            onClosed: (_) => _search(),
            closedBuilder: (context, openContainer) => MemoCard(
              clubName: clubName,
              clubCategory: _clubCategories[memo.clubId],
              clubIsCustom: _clubIsCustom[memo.clubId] ?? false,
              mediaItems: mediaItems,
              distance: memo.distance != null ? '${memo.distance}yd' : null,
              shotShape: memo.shotShape,
              condition: memo.condition,
              wind: memo.wind,
              bodyText: memo.body,
              date: _formatDate(memo.practicedAt, context),
              onTap: openContainer,
              margin: EdgeInsets.zero,
            ),
            openBuilder: (context, _) => MemoExpandedCard(
              memo: memo,
              clubName: clubName,
              onChanged: _search,
            ),
          ),
        );
      },
    );
  }
}

// ── クラブ選択フィルター（DBから読み込み） ──────────────
class _ClubFilterContent extends StatefulWidget {
  final int? selectedId;
  final void Function(int id, String name) onApply;
  final VoidCallback onClear;
  final ScrollController? scrollController;

  const _ClubFilterContent({
    required this.selectedId,
    required this.onApply,
    required this.onClear,
    this.scrollController,
  });

  @override
  State<_ClubFilterContent> createState() => _ClubFilterContentState();
}

class _ClubFilterContentState extends State<_ClubFilterContent> {
  final _clubRepo = ClubRepository();
  List<Map<String, dynamic>> _clubGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveOnClubs();
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent(club.category, () => []).add(club);
    }
    setState(() {
      _clubGroups = grouped.entries
          .map((e) => {'category': e.key, 'clubs': e.value})
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _clubGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = _clubGroups[groupIndex];
        final clubs = group['clubs'] as List<Club>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(title: group['category'] as String),
            ...clubs.map((club) {
              final parenIdx = club.name.indexOf('（');
              final hasSubtitle = parenIdx != -1;
              final mainName = hasSubtitle ? club.name.substring(0, parenIdx) : club.name;
              final subName = hasSubtitle ? club.name.substring(parenIdx) : '';
              final isSelected = widget.selectedId == club.id;
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
                            Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                            Text(subName, style: AppTypography.jpSRegular.copyWith(color: AppColors.textSecondary)),
                          ],
                        )
                      : Text(mainName, style: AppTypography.jpMRegular.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    if (isSelected) {
                      widget.onClear();
                    } else {
                      widget.onApply(club.id!, club.name);
                    }
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── 記録日フィルター ─────────────────────────────────
class _DateFilterContent extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _DateFilterContent({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (value: null as String?,      label: l10n.filterNone),
      (value: 'month1' as String?,  label: l10n.dateRange1m),
      (value: 'month6' as String?,  label: l10n.dateRange6m),
      (value: 'year1' as String?,   label: l10n.dateRange1y),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = selected == opt.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              minTileHeight: 56,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                opt.label,
                style: AppTypography.jpMRegular.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => onSelect(opt.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 飛距離フィルター ─────────────────────────────────
class _DistanceFilterContent extends StatefulWidget {
  final int? min;
  final int? max;
  final Function(int?, int?) onApply;
  final VoidCallback onClear;

  const _DistanceFilterContent({
    required this.min,
    required this.max,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_DistanceFilterContent> createState() => _DistanceFilterContentState();
}

class _DistanceFilterContentState extends State<_DistanceFilterContent> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.min?.toString());
    _maxCtrl = TextEditingController(text: widget.max?.toString());
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: AppTypography.enMMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('yd', style: AppTypography.enMMedium.copyWith(color: AppColors.textPlaceholder)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('〜', style: TextStyle(fontSize: 16, color: AppColors.textMedium)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: AppTypography.enMMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('yd', style: AppTypography.enMMedium.copyWith(color: AppColors.textPlaceholder)),
            ],
          ),
        ),
        _SheetButtons(
          applyColor: AppColors.primary,
          onApply: () {
            widget.onApply(
              int.tryParse(_minCtrl.text),
              int.tryParse(_maxCtrl.text),
            );
            Navigator.pop(context);
          },
          onClear: () {
            widget.onClear();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ── 調子フィルター ────────────────────────────────────
class _ConditionFilterContent extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onApply;
  final VoidCallback onClear;

  const _ConditionFilterContent({
    required this.selected,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final entries = AppConstants.conditionLabels.entries.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: entries.map((e) {
          final isSelected = selected == e.key;
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              minTileHeight: 56,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                e.value,
                style: AppTypography.jpMRegular.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                onApply(isSelected ? null : e.key);
                Navigator.pop(context);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 球筋フィルター（マルチセレクト） ─────────────────────
class _ShotShapeFilterContent extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;
  final VoidCallback onClear;

  const _ShotShapeFilterContent({
    required this.selected,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ShotShapeFilterContent> createState() => _ShotShapeFilterContentState();
}

class _ShotShapeFilterContentState extends State<_ShotShapeFilterContent> {
  late Set<String> _temp;

  @override
  void initState() {
    super.initState();
    _temp = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final entries = AppConstants.shotShapeLabels.entries.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: entries.map((e) {
              final isSelected = _temp.contains(e.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  minTileHeight: 56,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    e.value,
                    style: AppTypography.jpMRegular.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _temp.remove(e.key);
                      } else {
                        _temp.add(e.key);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        _SheetButtons(
          applyColor: AppColors.primary,
          onApply: () {
            widget.onApply(Set.from(_temp));
            Navigator.pop(context);
          },
          onClear: () {
            widget.onClear();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ── 適用・クリアボタン（共通） ────────────────────────
class _SheetButtons extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onClear;
  final Color applyColor;

  const _SheetButtons({
    required this.onApply,
    required this.onClear,
    this.applyColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          AppPrimaryButton(
            label: '適用',
            onPressed: onApply,
            color: applyColor,
          ),
          AppTextButton(
            label: 'クリア',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
