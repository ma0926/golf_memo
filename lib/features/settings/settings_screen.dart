import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../shared/widgets/app_list_tile.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '設定',
          style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SettingsRow(
            label: '記録するクラブ',
            icon: 'assets/icons/settings_club.svg',
            onTap: () => context.push('/settings/clubs'),
          ),
          _SettingsRow(
            label: 'お問い合わせ',
            icon: 'assets/icons/settings_contact.svg',
            onTap: () {},
          ),
          _SettingsRow(
            label: '規約・ライセンス',
            icon: 'assets/icons/settings_terms.svg',
            onTap: () => context.push('/settings/terms'),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _SettingsRow({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: label,
      leading: SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
