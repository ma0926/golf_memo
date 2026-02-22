import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';

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
  String? get _dateLabel {
    switch (_selectedDate) {
      case 'month1': return '1ヶ月以前';
      case 'month6': return '6ヶ月以前';
      case 'year1':  return '1年以前';
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
    _showFilterSheet(
      title: 'クラブ',
      child: _ClubFilterContent(
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
    );
  }

  void _openDateSheet() {
    _showFilterSheet(
      title: '記録日',
      child: _DateFilterContent(
        selected: _selectedDate,
        onSelect: (value) {
          setState(() => _selectedDate = value);
          Navigator.pop(context);
        },
      ),
      showButtons: false,
    );
  }

  void _openDistanceSheet() {
    _showFilterSheet(
      title: '飛距離',
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
    _showFilterSheet(
      title: '調子',
      child: _ConditionFilterContent(
        selected: _selectedCondition,
        onApply: (value) => setState(() => _selectedCondition = value),
        onClear: () => setState(() => _selectedCondition = null),
      ),
    );
  }

  void _openShotShapeSheet() {
    _showFilterSheet(
      title: '球筋',
      showButtons: false,
      child: _ShotShapeFilterContent(
        selected: _selectedShotShapes,
        onChanged: (values) => setState(() => _selectedShotShapes = values),
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
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ドラッグインジケーター
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 検索バー
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'キーワード検索',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            // フィルターチップ（横スクロール）
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'お気に入り',
                    isSelected: _isFavorite,
                    isToggle: true,
                    showArrow: false,
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '添付ファイル',
                    isSelected: _hasAttachment,
                    isToggle: true,
                    showArrow: false,
                    onTap: () => setState(() => _hasAttachment = !_hasAttachment),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'クラブ',
                    isSelected: _selectedClubId != null,
                    showArrow: true,
                    selectedLabel: _selectedClubName,
                    onTap: _openClubSheet,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '記録日',
                    isSelected: _selectedDate != null,
                    showArrow: true,
                    selectedLabel: _dateLabel,
                    onTap: _openDateSheet,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '飛距離',
                    isSelected: _distanceMin != null || _distanceMax != null,
                    showArrow: true,
                    selectedLabel: _distanceLabel,
                    onTap: _openDistanceSheet,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '調子',
                    isSelected: _selectedCondition != null,
                    showArrow: true,
                    selectedLabel: _selectedCondition != null
                        ? AppConstants.conditionLabels[_selectedCondition]
                        : null,
                    onTap: _openConditionSheet,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '球筋',
                    isSelected: _selectedShotShapes.isNotEmpty,
                    showArrow: true,
                    selectedLabel: _shotShapeLabel,
                    onTap: _openShotShapeSheet,
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
    final isDropdownSelected = isSelected && !isToggle;

    final borderColor = (isToggle && isSelected) || isDropdownSelected
        ? AppColors.primary
        : AppColors.divider;
    final textColor = (isToggle && isSelected) || isDropdownSelected
        ? AppColors.primary
        : AppColors.textPrimary;

    final displayLabel = isDropdownSelected && selectedLabel != null
        ? selectedLabel!
        : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToggle && isSelected) ...[
              const Icon(Icons.check, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              displayLabel,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
            if (showArrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down, size: 14, color: textColor),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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

  List<PracticeMemo> _results = [];
  Map<int, String> _clubNames = {};
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
      }
      // 削除済みクラブは個別に取得
      for (final memo in results) {
        if (!clubMap.containsKey(memo.clubId)) {
          final club = await _clubRepo.getClubById(memo.clubId);
          if (club != null) clubMap[memo.clubId] = club.name;
        }
      }
    }

    if (mounted) {
      setState(() {
        _results = results;
        _clubNames = clubMap;
        _isLoading = false;
      });
    }
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

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          '記録が見つかりませんでした',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final memo = _results[index];
        final clubName = _clubNames[memo.clubId] ?? '不明なクラブ';

        return GestureDetector(
          onTap: () => context.push('/memo/${memo.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(memo.practicedAt),
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
                    const Spacer(),
                    if (memo.distance != null)
                      Text(
                        '${memo.distance}yd',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (memo.body != null && memo.body!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    memo.body!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
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

  const _ClubFilterContent({
    required this.selectedId,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ClubFilterContent> createState() => _ClubFilterContentState();
}

class _ClubFilterContentState extends State<_ClubFilterContent> {
  final _clubRepo = ClubRepository();
  List<Club> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveClubs();
    setState(() {
      _clubs = clubs;
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

    return SizedBox(
      height: 280,
      child: ListView(
        children: _clubs.map((club) {
          final isSelected = widget.selectedId == club.id;
          return Column(
            children: [
              ListTile(
                title: Text(club.name),
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
              const Divider(height: 0.5, indent: 16, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 記録日フィルター ─────────────────────────────────
class _DateFilterContent extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _DateFilterContent({required this.selected, required this.onSelect});

  static const _options = [
    (value: null,      label: '指定なし'),
    (value: 'month1',  label: '1ヶ月以上前'),
    (value: 'month6',  label: '6ヶ月以上前'),
    (value: 'year1',   label: '1年以上前'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(_options.length, (i) {
              final opt = _options[i];
              final isSelected = selected == opt.value;
              return Column(
                children: [
                  ListTile(
                    title: Text(opt.label),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () => onSelect(opt.value),
                  ),
                  if (i < _options.length - 1)
                    const Divider(height: 0.5, indent: 16, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('yd 〜', style: TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('yd', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
        _SheetButtons(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final isSelected = selected == e.key;
              return Column(
                children: [
                  ListTile(
                    title: Text(e.value),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      onApply(isSelected ? null : e.key);
                      Navigator.pop(context);
                    },
                  ),
                  if (i < entries.length - 1)
                    const Divider(height: 0.5, indent: 16, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── 球筋フィルター（マルチセレクト） ─────────────────────
class _ShotShapeFilterContent extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _ShotShapeFilterContent({
    required this.selected,
    required this.onChanged,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.shotShapeLabels.entries.map((e) {
          final isSelected = _temp.contains(e.key);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _temp.remove(e.key);
                } else {
                  _temp.add(e.key);
                }
              });
              widget.onChanged(Set.from(_temp));
            },
            child: Container(
              width: (MediaQuery.of(context).size.width - 52) / 3,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.north_east,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 適用・クリアボタン（共通） ────────────────────────
class _SheetButtons extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _SheetButtons({required this.onApply, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                '適用',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'クリア',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
