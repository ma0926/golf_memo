import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 練習するクラブ
          _SettingsGroup(
            children: [
              _SettingsRow(
                label: '練習するクラブ',
                onTap: () => context.push('/settings/clubs'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // このアプリについて
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'このアプリについて',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          _SettingsGroup(
            children: [
              _SettingsRow(label: 'お問い合わせ', onTap: () {}),
              _SettingsRow(label: '利用規約', onTap: () {}),
              _SettingsRow(label: 'プライバシーポリシー', onTap: () {}),
              _SettingsRow(label: 'ライセンス', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(height: 0.5, indent: 16, color: AppColors.divider);
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
