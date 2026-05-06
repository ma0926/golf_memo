import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/repositories/club_repository.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/sheet_drag_handle.dart';
import 'package:golf_memo/l10n/app_localizations.dart';

class CustomClubScreen extends StatefulWidget {
  final int? clubId; // null = 新規, 非null = 既存クラブを編集
  final String? initialCategory; // 新規作成時の初期カテゴリ

  const CustomClubScreen({super.key, this.clubId, this.initialCategory});

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
      setState(() {
        _selectedCategory = widget.initialCategory;
        _isLoading = false;
      });
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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteCustomClub),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _clubRepo.deleteClub(widget.clubId!);
              if (mounted) context.pop();
            },
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetDragHandle(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                AppLocalizations.of(ctx)!.labelClubCategory,
                textAlign: TextAlign.center,
                style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
              ),
            ),
            // カテゴリ一覧
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: AppConstants.clubCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return AppListTile(
                    title: cat,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
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
        leadingWidth: 100,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            AppLocalizations.of(context)!.actionCancel,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.titleCustomClub,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: (_canSave && !_isSaving) ? _save : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.actionSave,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _canSave ? AppColors.primary : AppColors.textSecondary,
                ),
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
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: _isNew,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.placeholderClubName,
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
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
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context)!.labelClubCategory,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCategory ?? AppLocalizations.of(context)!.placeholderCategory,
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
                  child: Text(
                    AppLocalizations.of(context)!.actionDeleteClub,
                    style: const TextStyle(fontSize: 15, color: Colors.red),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
