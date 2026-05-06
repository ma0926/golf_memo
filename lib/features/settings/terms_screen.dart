import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'package:golf_memo/l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 48,
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
        title: Text(
          AppLocalizations.of(context)!.settingsTerms,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(title: AppLocalizations.of(context)!.sectionTermsOfUse, body: ''),
          const SizedBox(height: 32),
          _Section(title: AppLocalizations.of(context)!.sectionPrivacy, body: ''),
          const SizedBox(height: 32),
          _Section(
            title: AppLocalizations.of(context)!.sectionLicense,
            body: 'このアプリは以下のオープンソースソフトウェアを使用しています。\n\n'
                '• Flutter (BSD 3-Clause License)\n'
                '• sqflite (MIT License)\n'
                '• go_router (BSD 3-Clause License)\n'
                '• image_picker (BSD 3-Clause License)\n'
                '• video_player (BSD 3-Clause License)\n'
                '• video_compress (MIT License)\n'
                '• video_thumbnail (BSD 3-Clause License)\n'
                '• fl_chart (MIT License)\n'
                '• path_provider (BSD 3-Clause License)\n'
                '• shared_preferences (BSD 3-Clause License)\n'
                '• path (MIT License)\n'
                '• cupertino_icons (MIT License)',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: body.isEmpty
              ? Text(
                  AppLocalizations.of(context)!.placeholderPreparing,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              : Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
        ),
      ],
    );
  }
}
