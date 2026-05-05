import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_section_title.dart';
import '../../shared/widgets/memo_card.dart' show ClubBadge;
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
        child: CustomScrollView(
          slivers: [
            // ヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/club_setting.svg',
                      width: 120,
                      height: 117,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '練習で使用するクラブを\n教えてください。',
                      textAlign: TextAlign.center,
                      style: AppTypography.jpHeader2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'クラブごとにコツや飛距離を記録できます。',
                      textAlign: TextAlign.center,
                      style: AppTypography.jpMRegular.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '設定はいつでも変えられます。',
                      textAlign: TextAlign.center,
                      style: AppTypography.jpMRegular.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // カテゴリタブ
            SliverToBoxAdapter(child: _buildTabRow()),
            // クラブリスト
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...grouped.entries.map((e) => _buildCategoryGroup(e.key, e.value)),
                  GestureDetector(
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'カスタムクラブを追加',
                              style: AppTypography.jpMMedium.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppPrimaryButton(
            label: '次へ',
            onPressed: _onNext,
            color: _buttonColor,
            height: 52,
            borderRadius: 12,
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
        separatorBuilder: (_, __) => const SizedBox(width: 4),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab,
                style: AppTypography.jpSMedium.copyWith(
                  color: isSelected ? AppColors.background : AppColors.textMedium,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
        ...clubs.map((club) {
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
              trailing: Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: club.isActive,
                  onChanged: (v) => _toggleClub(club, v),
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
