import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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
  final Set<String> _expandedCategories = {};
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupedClubs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 20),
              Text('戻る', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
        title: const Text(
          '練習するクラブ',
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
          // カテゴリタブ
          _buildTabRow(),
          // クラブリスト
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...grouped.entries.map((e) => _buildCategoryGroup(e.key, e.value)),
                // カスタムクラブ追加ボタン
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: GestureDetector(
                    onTap: () async {
                      await context.push('/settings/clubs/new');
                      _load();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 15, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'カスタムクラブを追加',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.divider,
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup(String category, List<Club> clubs) {
    final isExpanded = _expandedCategories.contains(category);
    final onClubs = clubs.where((c) => c.isActive).toList();

    // ONのクラブが0件の場合は全件表示（折りたたむと何も見えなくなるため）
    final displayClubs = (isExpanded || onClubs.isEmpty) ? clubs : onClubs;
    final hasHidden = !isExpanded && onClubs.isNotEmpty && clubs.length > onClubs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6, left: 4),
          child: Text(
            category,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ...List.generate(displayClubs.length, (i) {
                final club = displayClubs[i];
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        club.name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: CupertinoSwitch(
                        value: club.isActive,
                        onChanged: (v) => _toggleClub(club, v),
                        activeTrackColor: Colors.green,
                      ),
                      // カスタムクラブはタップで編集画面へ
                      onTap: club.isCustom
                          ? () async {
                              await context.push('/settings/clubs/${club.id}/edit');
                              _load();
                            }
                          : null,
                    ),
                    if (i < displayClubs.length - 1 || hasHidden)
                      const Divider(height: 0.5, indent: 16, color: AppColors.divider),
                  ],
                );
              }),
              // すべて表示リンク
              if (hasHidden)
                InkWell(
                  onTap: () => setState(() => _expandedCategories.add(category)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'すべて表示',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
