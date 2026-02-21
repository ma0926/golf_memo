import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/media_preview_screen.dart';

class MemoDetailScreen extends StatefulWidget {
  final int memoId;

  const MemoDetailScreen({super.key, required this.memoId});

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  // ※ 後でデータベースから取得します。現在はレイアウト確認用のダミーデータです。
  bool _isFavorite = true;
  int _currentImageIndex = 0;

  final _dummyImages = [
    'https://via.placeholder.com/300',
    'https://via.placeholder.com/300',
    'https://via.placeholder.com/300',
  ];

  // 「...」ボタンのアクションシート
  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 編集画面へ遷移
            },
            child: const Text('編集'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirm();
            },
            child: const Text('削除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // 削除確認ダイアログ
  void _showDeleteConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この記録を削除すると元に戻せません。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
              // TODO: データベースから削除
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: _showActionSheet,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              // TODO: データベースを更新
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // クラブ名
            const Text(
              'ドライバー', // TODO: 実際のデータを表示
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // 日付
            const Text(
              '2026/1/12（金）', // TODO: 実際のデータを表示
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // メタ情報
            _MetaInfoRow(
              condition: 'good',
              distance: 250,
              shotShape: 'draw',
              wind: 'normal',
            ),
            const SizedBox(height: 20),
            // メモ本文
            const Text(
              'ソールをまず地面につけてクラブを置き、クラブの重みを感じながら、そのままテークバックしていく。\n\n脱力したまま腰でテークバックしていき、打つ！\n\nクラブの重みを感じられて良し！',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            // 画像ギャラリー
            _ImageGallery(
              imagePaths: _dummyImages,
              currentIndex: _currentImageIndex,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}

// ── メタ情報の横並び行 ──────────────────────────────
class _MetaInfoRow extends StatelessWidget {
  final String? condition;
  final int? distance;
  final String? shotShape;
  final String? wind;

  const _MetaInfoRow({
    this.condition,
    this.distance,
    this.shotShape,
    this.wind,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (condition != null)
          _MetaChip(
            icon: Icons.thumb_up_outlined,
            label: AppConstants.conditionLabels[condition] ?? condition!,
          ),
        if (distance != null)
          _MetaChip(
            icon: Icons.place_outlined,
            label: '${distance}yd',
          ),
        if (shotShape != null)
          _MetaChip(
            icon: Icons.north_east,
            label: AppConstants.shotShapeLabels[shotShape] ?? shotShape!,
          ),
        if (wind != null)
          _MetaChip(
            icon: Icons.air,
            label: AppConstants.windLabels[wind] ?? wind!,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── 画像ギャラリー ──────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final List<String> imagePaths;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.imagePaths,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: imagePaths.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // TODO: 実際のファイルパスに差し替え（現在はダミー）
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const MediaPreviewScreen(file: null),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: AppColors.divider, // TODO: 実際の画像に差し替え
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ページインジケーター（ドット）
        if (imagePaths.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imagePaths.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == currentIndex ? 16 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: index == currentIndex
                      ? AppColors.textPrimary
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
