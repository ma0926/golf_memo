import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../shared/widgets/app_section_title.dart';
import 'package:golf_memo/l10n/app_localizations.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.titleSettings,
          style: AppTypography.jpHeader2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          _SettingsRow(
            label: l10n.settingsClubs,
            icon: 'assets/icons/settings_club.svg',
            onTap: () => context.push('/settings/clubs'),
          ),
          AppSectionTitle(title: l10n.settingsAbout),
          _SettingsRow(
            label: l10n.settingsContact,
            icon: 'assets/icons/settings_contact.svg',
            onTap: () {},
          ),
          _SettingsRow(
            label: l10n.settingsTerms,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
        ),
        title: Text(
          label,
          style: AppTypography.jpMRegular.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
