import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';

class CustomClubScreen extends StatefulWidget {
  final int? clubId; // null = 新規, 非null = 既存クラブを編集

  const CustomClubScreen({super.key, this.clubId});

  @override
  State<CustomClubScreen> createState() => _CustomClubScreenState();
}

class _CustomClubScreenState extends State<CustomClubScreen> {
  final _clubRepo = ClubRepository();
  final _nameController = TextEditingController();

  Club? _existingClub;
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isNew => widget.clubId == null;
  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _selectedCategory != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_isNew) {
      setState(() => _isLoading = false);
      return;
    }

    final club = await _clubRepo.getClubById(widget.clubId!);
    if (club == null) {
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _existingClub = club;
      _nameController.text = club.name;
      _selectedCategory = club.category;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_isNew) {
        // sort_order を末尾に設定
        final allClubs = await _clubRepo.getActiveClubs();
        final maxOrder = allClubs.isEmpty
            ? 0
            : allClubs.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
        await _clubRepo.insertClub(Club(
          name: _nameController.text.trim(),
          category: _selectedCategory!,
          sortOrder: maxOrder + 1,
          isActive: true,
          isCustom: true,
          createdAt: DateTime.now(),
        ));
      } else {
        await _clubRepo.updateClub(_existingClub!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
        ));
      }
      if (mounted) context.pop();
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  void _showDeleteConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('このカスタムクラブを削除します。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _clubRepo.deleteClub(widget.clubId!);
              if (mounted) context.pop();
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグインジケーター + タイトル
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'クラブのカテゴリ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // カテゴリ一覧
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: List.generate(
                  AppConstants.clubCategories.length,
                  (i) {
                    final cat = AppConstants.clubCategories[i];
                    final isSelected = _selectedCategory == cat;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
                          },
                        ),
                        if (i < AppConstants.clubCategories.length - 1)
                          const Divider(
                            height: 0.5,
                            indent: 16,
                            color: AppColors.divider,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'キャンセル',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        title: const Text(
          'カスタムクラブ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_canSave && !_isSaving) ? _save : null,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _canSave ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // クラブ名入力
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: _isNew,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'クラブ名を入力',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // カテゴリ選択
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'クラブのカテゴリ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCategory ?? 'カテゴリ選択',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedCategory != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 削除ボタン（既存のカスタムクラブのみ表示）
          if (!_isNew)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: _showDeleteConfirm,
                  child: const Text(
                    'このクラブを削除する',
                    style: TextStyle(fontSize: 15, color: Colors.red),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
