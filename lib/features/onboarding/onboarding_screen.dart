import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';
import '../settings/custom_club_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _clubRepo = ClubRepository();

  List<Club> _clubs = [];
  String _selectedTab = 'すべて';
  bool _isLoading = true;

  static const _tabs = ['すべて', ...AppConstants.clubCategories];

  // 「次へ」ボタンの色（Figmaのダークネイビー）
  static const _buttonColor = Color(0xFF2B3562);

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

  Future<void> _toggleClub(Club club, bool newValue) async {
    setState(() {
      final index = _clubs.indexWhere((c) => c.id == club.id);
      if (index != -1) _clubs[index] = club.copyWith(isActive: newValue);
    });
    await _clubRepo.updateClub(club.copyWith(isActive: newValue));
  }

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

  Future<void> _onNext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/home');
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
      body: SafeArea(
        child: Column(
          children: [
            // タイトル
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Text(
                'あなたの練習するクラブを\n選択してください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            // カテゴリタブ
            _buildTabRow(),
            // クラブリスト
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...grouped.entries.map((e) => _buildCategoryGroup(e.key, e.value)),
                  // カスタムクラブ追加リンク
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.92,
                          ),
                          builder: (_) => ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CustomClubScreen(
                              initialCategory: _selectedTab == 'すべて' ? null : _selectedTab,
                            ),
                          ),
                        );
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
      ),
      // 次へボタン（画面下部に固定）
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '次へ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? Colors.white : AppColors.textPrimary,
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
            children: List.generate(clubs.length, (i) {
              final club = clubs[i];
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
                  ),
                  if (i < clubs.length - 1)
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
