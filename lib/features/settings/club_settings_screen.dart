import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_section_title.dart';
import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';

class ClubSettingsScreen extends StatefulWidget {
  const ClubSettingsScreen({super.key});

  @override
  State<ClubSettingsScreen> createState() => _ClubSettingsScreenState();
}

class _ClubSettingsScreenState extends State<ClubSettingsScreen> {
  final _clubRepo = ClubRepository();

  List<Club> _clubs = [];
  String _selectedTab = 'すべて';
  bool _isLoading = true;

  static const _tabs = ['すべて', ...AppConstants.clubCategories];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clubs = await _clubRepo.getActiveClubs();
    if (mounted) {
      setState(() {
        _clubs = clubs;
        _isLoading = false;
      });
    }
  }

  // スイッチ切り替え時に即座にDBへ保存
  Future<void> _toggleClub(Club club, bool newValue) async {
    setState(() {
      final index = _clubs.indexWhere((c) => c.id == club.id);
      if (index != -1) {
        _clubs[index] = club.copyWith(isActive: newValue);
      }
    });
    await _clubRepo.updateClub(club.copyWith(isActive: newValue));
  }

  // 選択中タブに応じてグループ化したクラブを返す
  Map<String, List<Club>> get _groupedClubs {
    final categories = _selectedTab == 'すべて'
        ? AppConstants.clubCategories
        : [_selectedTab];
    return {
      for (final cat in categories)
        if (_clubs.any((c) => c.category == cat))
          cat: _clubs.where((c) => c.category == cat).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupedClubs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: SvgPicture.asset(
            'assets/icons/chevron_left.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
          ),
        ),
        title: const Text(
          '記録するクラブ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // カテゴリタブ
          _buildTabRow(),
          // クラブリスト
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ...grouped.entries.map((e) => _buildCategoryGroup(e.key, e.value)),
                // カスタムクラブ追加ボタン
                GestureDetector(
                  onTap: () async {
                    await context.push('/settings/clubs/new');
                    _load();
                  },
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: Color(0xFF0051FF)),
                        const SizedBox(width: 4),
                        Text(
                          'カスタムクラブを追加',
                          style: AppTypography.jpMMedium.copyWith(
                            color: const Color(0xFF0051FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _tabs.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab,
                style: AppTypography.jpSMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildCategoryGroup(String category, List<Club> clubs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(title: category),
        Column(
          children: clubs.map((club) {
            return AppListTile(
              title: club.name,
              trailing: Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: club.isActive,
                  onChanged: (v) => _toggleClub(club, v),
                  activeTrackColor: Colors.green,
                ),
              ),
              onTap: club.isCustom
                  ? () async {
                      await context.push('/settings/clubs/${club.id}/edit');
                      _load();
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
