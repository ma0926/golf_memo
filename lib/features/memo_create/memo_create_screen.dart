import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../settings/club_settings_screen.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/media_preview_screen.dart';
import '../../shared/widgets/media_picker_screen.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_distance_input.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_section_title.dart';
import '../../shared/widgets/memo_card.dart' show ClubBadge;
import '../../shared/widgets/sheet_drag_handle.dart';

// ──────────────────────────────────────────────────────
// ルート：ローカルNavigatorでクラブ選択→フォームを管理
// ──────────────────────────────────────────────────────
class MemoCreateScreen extends StatelessWidget {
  const MemoCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outerContext = context;

    return Navigator(
      onGenerateRoute: (_) => CupertinoPageRoute(
        builder: (ctx) => _ClubSelectPage(
          onClose: () => Navigator.of(outerContext).pop(),
          onClubSelected: (int clubId, String clubName) {
            Navigator.of(ctx).push(
              CupertinoPageRoute(
                builder: (_) => _MemoInputPage(
                  clubId: clubId,
                  clubName: clubName,
                  onSave: () => Navigator.of(outerContext).pop(true),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// クラブ選択ページ（DBから読み込み）
// ──────────────────────────────────────────────────────
class _ClubSelectPage extends StatefulWidget {
  final void Function(int clubId, String clubName) onClubSelected;
  final VoidCallback onClose;

  const _ClubSelectPage({
    required this.onClubSelected,
    required this.onClose,
  });

  @override
  State<_ClubSelectPage> createState() => _ClubSelectPageState();
}

class _ClubSelectPageState extends State<_ClubSelectPage> {
  final _clubRepo = ClubRepository();
  List<Map<String, dynamic>> _clubGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveOnClubs();
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent(club.category, () => []).add(club);
    }
    setState(() {
      _clubGroups = grouped.entries
          .map((e) => {'category': e.key, 'clubs': e.value})
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'クラブを選択',
                      textAlign: TextAlign.center,
                      style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/close.svg',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // クラブリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                itemCount: _clubGroups.length + 1,
                itemBuilder: (context, index) {
                  // 設定画面への動線
                  if (index == _clubGroups.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0x57545456),
                            width: 0.33,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const ClubSettingsScreen(),
                                transitionsBuilder: (_, animation, __, child) => SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'クラブを編集',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // クラブグループ
                  final group = _clubGroups[index];
                  final clubs = group['clubs'] as List<Club>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionTitle(title: group['category'] as String),
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
                            onTap: () => widget.onClubSelected(club.id!, club.name),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// メモ入力ページ
// ──────────────────────────────────────────────────────
class _MemoInputPage extends StatefulWidget {
  final int clubId;
  final String clubName;
  final VoidCallback onSave;

  const _MemoInputPage({
    required this.clubId,
    required this.clubName,
    required this.onSave,
  });

  @override
  State<_MemoInputPage> createState() => _MemoInputPageState();
}

class _MemoInputPageState extends State<_MemoInputPage> {
  late int _clubId;
  late String _clubName;
  DateTime _selectedDate = DateTime.now();
  final _bodyController = TextEditingController();
  final _distanceController = TextEditingController();
  final _distanceFocusNode = FocusNode();
  final Set<String> _openSections = {};

  String? _shotShape;
  String? _condition;
  String? _wind;

  // メディア
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  XFile? _video;
  String? _videoThumbnailPath;

  // 保存処理
  final _memoRepo = PracticeMemoRepository();
  final _mediaRepo = MediaRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _clubId = widget.clubId;
    _clubName = widget.clubName;
    _bodyController.addListener(() => setState(() {}));
    _distanceController.addListener(() => setState(() {}));
  }

  void _showClubSelect() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _ClubSelectSheet(
          scrollController: scrollController,
          onClubSelected: (id, name) {
            Navigator.pop(sheetContext);
            if (mounted) setState(() { _clubId = id; _clubName = name; });
          },
          onOpenSettings: () {
            Navigator.pop(sheetContext);
            Future.microtask(() { if (mounted) context.push('/settings'); });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _distanceController.dispose();
    _distanceFocusNode.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    if (diff <= 6) return '$diff日前';
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[_selectedDate.weekday - 1];
    return '${_selectedDate.month}月${_selectedDate.day}日 ${w}曜日';
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => Container(
        height: 280,
        color: Colors.white,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                child: const Text('完了', style: TextStyle(color: AppColors.primary)),
                onPressed: () => Navigator.pop(modalContext),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) => setState(() => _selectedDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── メディア ─────────────────────────────────────────

  void _showMediaPicker() {
    if (_images.length >= AppConstants.maxImagesPerMemo && _video != null) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetDragHandle(),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/photo_library.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
              ),
              title: Text(
                'ライブラリから選ぶ',
                style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromLibrary();
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/camera_add.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
              ),
              title: Text(
                '写真を撮る',
                style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  '※動画は1枚、画像は3枚まで追加できます。',
                  style: AppTypography.jpSRegular.copyWith(color: AppColors.textPlaceholder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromLibrary() async {
    final remainingImages = AppConstants.maxImagesPerMemo - _images.length;
    if (remainingImages <= 0 && _video != null) return;

    final result = await Navigator.of(context, rootNavigator: true).push<
        ({List<XFile> images, XFile? video})?>(
      MaterialPageRoute(
        builder: (_) => MediaPickerScreen(
          maxImages: remainingImages,
          videoAllowed: _video == null,
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result.images.isNotEmpty) {
      setState(() => _images.addAll(result.images));
    }
    if (result.video != null) {
      await _setVideo(result.video!);
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _images.add(file));
  }

  Future<void> _setVideo(XFile file) async {
    final dir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: dir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    setState(() {
      _video = file;
      _videoThumbnailPath = thumbnailPath;
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeVideo() {
    setState(() {
      _video = null;
      _videoThumbnailPath = null;
    });
  }

  void _showPreview(File? file, {bool isVideo = false, String? videoPath}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          file: file,
          isVideo: isVideo,
          videoPath: videoPath,
        ),
      ),
    );
  }

  // ── DB保存 ───────────────────────────────────────────

  Future<void> _saveMemo() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      // メモ保存
      final memo = PracticeMemo(
        clubId: _clubId,
        practicedAt: _selectedDate,
        body: _bodyController.text.trimRight().isEmpty ? null : _bodyController.text.trimRight(),
        condition: _condition,
        distance: int.tryParse(_distanceController.text),
        shotShape: _shotShape,
        wind: _wind,
        isFavorite: false,
        createdAt: now,
      );
      final savedMemo = await _memoRepo.insertMemo(memo);

      // メディアファイルをdocumentsに永続保存
      if (_images.isNotEmpty || _video != null) {
        final docsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory('${docsDir.path}/media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
        }

        for (final image in _images) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = image.path.split('.').last.toLowerCase();
          final relPath = 'media/img_$ts.$ext';
          await File(image.path).copy('${mediaDir.path}/img_$ts.$ext');
          await _mediaRepo.insertMedia(Media(
            practiceMemoId: savedMemo.id!,
            type: 'image',
            uri: relPath,
            createdAt: now,
          ));
        }

        if (_video != null) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = _video!.path.split('.').last.toLowerCase();
          final vidRelPath = 'media/vid_$ts.$ext';
          final vidDestPath = '${mediaDir.path}/vid_$ts.$ext';
          // ダミーファイル（空）の場合はコピーしない
          if (await File(_video!.path).length() > 0) {
            await File(_video!.path).copy(vidDestPath);
          }

          String? thumbRelPath;
          if (_videoThumbnailPath != null) {
            thumbRelPath = 'media/thumb_$ts.jpg';
            await File(_videoThumbnailPath!).copy('${mediaDir.path}/thumb_$ts.jpg');
          }

          await _mediaRepo.insertMedia(Media(
            practiceMemoId: savedMemo.id!,
            type: 'video',
            uri: vidRelPath,
            thumbnailUri: thumbRelPath,
            createdAt: now,
          ));
        }
      }

      widget.onSave();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('保存に失敗しました'),
            content: const Text('もう一度お試しください。'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ── ビルド ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final collapsedChips = <Widget>[
      if (!_openSections.contains('shotShape'))
        _CollapsedChip(label: '球筋', onTap: () => setState(() => _openSections.add('shotShape'))),
      if (!_openSections.contains('condition'))
        _CollapsedChip(label: '調子', onTap: () => setState(() => _openSections.add('condition'))),
      if (!_openSections.contains('wind'))
        _CollapsedChip(label: '風', onTap: () => setState(() => _openSections.add('wind'))),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundExLow,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundExLow,
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/close.svg', width: 30, height: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppPrimaryButton(
              label: '保存',
              onPressed: _saveMemo,
              isLoading: _isSaving,
              icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              color: AppColors.primary,
              borderRadius: 24,
              fullWidth: false,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日付
                          Center(
                            child: GestureDetector(
                              onTap: _showDatePicker,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formattedDate,
                                    style: AppTypography.jpSMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  SvgPicture.asset('assets/icons/calendar.svg', width: 20, height: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // クラブ名
                          GestureDetector(
                            onTap: _showClubSelect,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _clubName,
                                  style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 6),
                                SvgPicture.asset('assets/icons/edit_pen.svg', width: 20, height: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 飛距離（固定表示）
                          Row(
                            children: [
                              Text(
                                '飛距離',
                                style: AppTypography.jpHeader4.copyWith(
                                  color: AppColors.textMedium,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _distanceController,
                                  focusNode: _distanceFocusNode,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.enMMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'yd',
                                style: AppTypography.enMMedium.copyWith(
                                  color: AppColors.textPlaceholder,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '練習内容・気づき',
                          hintStyle: AppTypography.jpMRegular.copyWith(color: AppColors.textPlaceholder, letterSpacing: 0, wordSpacing: 0),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary, letterSpacing: 0, wordSpacing: 0),
                      ),
                    ),
                    _buildCreateMediaGrid(),
                    if (_openSections.contains('shotShape') || _openSections.contains('condition') || _openSections.contains('wind'))
                      const SizedBox(height: 16),
                    if (_openSections.contains('shotShape'))
                      _buildSectionCard(
                        label: '球筋',
                        sectionKey: 'shotShape',
                        child: _ChipSelector(
                          options: AppConstants.shotShapeLabels.entries
                              .map((e) => (value: e.key, label: e.value, svgPath: 'assets/icons/${e.key}.svg', svgPathFilled: null))
                              .toList(),
                          selected: _shotShape,
                          onSelected: (v) => setState(() => _shotShape = v),
                          useGridLayout: true,
                        ),
                      ),
                    if (_openSections.contains('condition'))
                      _buildSectionCard(
                        label: '調子',
                        sectionKey: 'condition',
                        child: _ChipSelector(
                          options: AppConstants.conditionLabels.entries
                              .map((e) => (value: e.key, label: e.value, svgPath: AppConstants.conditionIcons[e.key], svgPathFilled: AppConstants.conditionIconsFilled[e.key]))
                              .toList(),
                          selected: _condition,
                          onSelected: (v) => setState(() => _condition = v),
                        ),
                      ),
                    if (_openSections.contains('wind'))
                      _buildSectionCard(
                        label: '風',
                        sectionKey: 'wind',
                        child: _ChipSelector(
                          options: AppConstants.windLabels.entries
                              .map((e) => (value: e.key, label: e.value, svgPath: AppConstants.windIcons[e.key], svgPathFilled: null))
                              .toList(),
                          selected: _wind,
                          onSelected: (v) => setState(() => _wind = v),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        ...collapsedChips,
                        const Spacer(),
                        if (_images.length < AppConstants.maxImagesPerMemo || _video == null)
                          GestureDetector(
                            onTap: _showMediaPicker,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundMiddle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: SvgPicture.asset('assets/icons/add_photo.svg', width: 22, height: 22),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateMediaGrid() {
    final items = <({File? file, bool isVideo, VoidCallback onRemove})>[];
    for (var i = 0; i < _images.length; i++) {
      final idx = i;
      items.add((
        file: File(_images[idx].path),
        isVideo: false,
        onRemove: () => _removeImage(idx),
      ));
    }
    if (_video != null) {
      items.add((
        file: _videoThumbnailPath != null ? File(_videoThumbnailPath!) : null,
        isVideo: true,
        onRemove: _removeVideo,
      ));
    }

    final count = items.length.clamp(0, 4);
    if (count == 0) return const SizedBox.shrink();

    Widget tile(int index) {
      final item = items[index];
      return Stack(
        fit: StackFit.expand,
        children: [
          if (item.file != null)
            Image.file(item.file!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundMiddle))
          else
            Container(color: const Color(0xFF2C2C2E),
                child: const Center(child: Icon(Icons.videocam, color: Colors.white54, size: 32))),
          if (item.isVideo)
            const Center(child: Icon(Icons.play_circle_filled, size: 36, color: Colors.white70)),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: item.onRemove,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }

    Widget grid;
    if (count == 1) {
      grid = tile(0);
    } else if (count == 2) {
      grid = Row(children: [Expanded(child: tile(0)), const SizedBox(width: 4), Expanded(child: tile(1))]);
    } else if (count == 3) {
      grid = Row(children: [
        Expanded(child: tile(0)),
        const SizedBox(width: 4),
        Expanded(child: Column(children: [Expanded(child: tile(1)), const SizedBox(height: 4), Expanded(child: tile(2))])),
      ]);
    } else {
      grid = Row(children: [
        Expanded(child: tile(0)),
        const SizedBox(width: 4),
        Expanded(child: Column(children: [
          Expanded(child: tile(1)),
          const SizedBox(height: 4),
          Expanded(child: Row(children: [Expanded(child: tile(2)), const SizedBox(width: 4), Expanded(child: tile(3))])),
        ])),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 165, child: grid),
      ),
    );
  }

  Widget _buildSectionCard({required String label, required String sectionKey, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F3F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(label, style: AppTypography.jpHeader4.copyWith(color: AppColors.textMedium, fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _openSections.remove(sectionKey)),
                    child: const Icon(Icons.close, size: 20, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

}

// ──────────────────────────────────────────────────────
// チップ選択（球筋・調子・風で共通）
// ──────────────────────────────────────────────────────
class _ChipSelector extends StatelessWidget {
  final List<({String value, String label, String? svgPath, String? svgPathFilled})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool useGridLayout;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.useGridLayout = false,
  });

  Widget _buildChip(({String value, String label, String? svgPath, String? svgPathFilled}) opt) {
    final isSelected = selected == opt.value;
    return GestureDetector(
      onTap: () => onSelected(isSelected ? null : opt.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHigh),
          boxShadow: null,
        ),
        child: Text(
          opt.label,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.jpSMedium.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useGridLayout && options.length == 5) {
      // 3＋2のグリッドレイアウト（球筋用）
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final opt in options) _buildChip(opt),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────
// 折りたたみ状態のセクションチップ（＋ラベル）
// ──────────────────────────────────────────────────────
class _CollapsedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CollapsedChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundMiddle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E1E5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.textMedium),
            const SizedBox(width: 2),
            Text(label, style: AppTypography.jpMMedium.copyWith(color: AppColors.textMedium, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// メディアサムネイル
// ──────────────────────────────────────────────────────
class _MediaThumbnail extends StatelessWidget {
  final File? file;
  final bool isVideo;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _MediaThumbnail({
    required this.file,
    required this.onRemove,
    this.isVideo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.divider,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: file != null
                  ? Image.file(file!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.videocam, size: 32, color: AppColors.textSecondary),
                    ),
            ),
          ),
        ),
        if (isVideo && file != null)
          const Positioned(
            bottom: 4,
            left: 4,
            child: Icon(Icons.play_circle_filled, size: 20, color: Colors.white),
          ),
        Positioned(
          top: -6,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────
// クラブ選択シート
// ──────────────────────────────────────────────────────
class _ClubSelectSheet extends StatefulWidget {
  final void Function(int clubId, String clubName) onClubSelected;
  final VoidCallback? onOpenSettings;
  final ScrollController? scrollController;

  const _ClubSelectSheet({
    required this.onClubSelected,
    this.onOpenSettings,
    this.scrollController,
  });

  @override
  State<_ClubSelectSheet> createState() => _ClubSelectSheetState();
}

class _ClubSelectSheetState extends State<_ClubSelectSheet> {
  final _clubRepo = ClubRepository();
  List<Map<String, dynamic>> _clubGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubRepo.getActiveOnClubs();
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent(club.category, () => []).add(club);
    }
    setState(() {
      _clubGroups = grouped.entries
          .map((e) => {'category': e.key, 'clubs': e.value})
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _clubGroups.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        const SheetDragHandle(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          child: SizedBox(
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  'クラブを選択',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.jpHeader3.copyWith(color: AppColors.textPrimary),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.close, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (index == _clubGroups.length + 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: GestureDetector(
                        onTap: widget.onOpenSettings,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('クラブの設定を開く', style: TextStyle(fontSize: 14, color: Colors.blue)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_outward, size: 14, color: Colors.blue),
                          ],
                        ),
                      ),
                    );
                  }
                  final group = _clubGroups[index - 1];
                  final clubs = group['clubs'] as List<Club>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionTitle(title: group['category'] as String),
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
                            onTap: () => widget.onClubSelected(club.id!, club.name),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
