import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/media_path_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/media_preview_screen.dart';
import '../../shared/widgets/media_picker_screen.dart';

class MemoEditScreen extends StatefulWidget {
  final int memoId;

  const MemoEditScreen({super.key, required this.memoId});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  final _memoRepo = PracticeMemoRepository();
  final _clubRepo = ClubRepository();
  final _mediaRepo = MediaRepository();

  PracticeMemo? _memo;
  int _clubId = 0;
  String _clubName = '';
  DateTime _selectedDate = DateTime.now();
  final _bodyController = TextEditingController();
  final _distanceController = TextEditingController();
  final _distanceFocusNode = FocusNode();

  String _docsPath = '';

  String? _shotShape;
  String? _condition;
  String? _wind;

  // メディア管理
  List<Media> _existingMedia = [];
  final Set<int> _removedMediaIds = {};
  final _picker = ImagePicker();
  final List<XFile> _newImages = [];
  XFile? _newVideo;
  String? _newVideoThumbnailPath;

  bool _isLoading = true;
  bool _isSaving = false;

  // 展開済みセクション（未選択のときは折りたたみ表示）
  final Set<String> _openSections = {};

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(() => setState(() {}));
    _distanceController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _distanceController.dispose();
    _distanceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final memo = await _memoRepo.getMemoById(widget.memoId);
    if (memo == null) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    final club = await _clubRepo.getClubById(memo.clubId);
    final media = await _mediaRepo.getMediaByMemoId(widget.memoId);
    final docsDir = await getApplicationDocumentsDirectory();

    setState(() {
      _memo = memo;
      _clubId = memo.clubId;
      _clubName = club?.name ?? '不明なクラブ';
      _selectedDate = memo.practicedAt;
      _bodyController.text = memo.body ?? '';
      _distanceController.text = memo.distance?.toString() ?? '';
      _shotShape = memo.shotShape;
      _condition = memo.condition;
      _wind = memo.wind;
      _existingMedia = media;
      _docsPath = docsDir.path;
      // 既に値が入っているセクションは最初から展開
      if (memo.distance != null) _openSections.add('distance');
      if (memo.shotShape != null) _openSections.add('shotShape');
      if (memo.condition != null) _openSections.add('condition');
      if (memo.wind != null) _openSections.add('wind');
      _isLoading = false;
    });
  }

  bool get _hasChanges {
    if (_memo == null) return false;
    final m = _memo!;
    return _clubId != m.clubId ||
        !_isSameDay(_selectedDate, m.practicedAt) ||
        _bodyController.text != (m.body ?? '') ||
        _distanceController.text != (m.distance?.toString() ?? '') ||
        _shotShape != m.shotShape ||
        _condition != m.condition ||
        _wind != m.wind ||
        _removedMediaIds.isNotEmpty ||
        _newImages.isNotEmpty ||
        _newVideo != null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    return '${_selectedDate.month}/${_selectedDate.day}（$w）';
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
                child: const Text('完了', style: TextStyle(color: AppColors.accent)),
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

  void _showClubSelect() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ClubSelectSheet(
        onClubSelected: (id, name) {
          Navigator.pop(sheetContext);
          if (mounted) {
            setState(() {
              _clubId = id;
              _clubName = name;
            });
          }
        },
        onOpenSettings: () {
          Navigator.pop(sheetContext);
          Future.microtask(() {
            if (mounted) context.push('/settings');
          });
        },
      ),
    );
  }

  // ── メディア ─────────────────────────────────────────

  int get _activeExistingImageCount =>
      _existingMedia.where((m) => m.isImage && !_removedMediaIds.contains(m.id)).length;

  bool get _hasActiveVideo =>
      _existingMedia.any((m) => m.isVideo && !_removedMediaIds.contains(m.id)) ||
      _newVideo != null;

  int get _totalImageCount => _activeExistingImageCount + _newImages.length;

  void _showMediaPicker() {
    if (_totalImageCount >= AppConstants.maxImagesPerMemo && _hasActiveVideo) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグインジケーター
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ライブラリから選ぶ
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
            // 写真を撮る
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
    final remainingImages = AppConstants.maxImagesPerMemo - _totalImageCount;
    if (remainingImages <= 0 && _hasActiveVideo) return;

    final result = await Navigator.of(context, rootNavigator: true).push<
        ({List<XFile> images, XFile? video})?>(
      MaterialPageRoute(
        builder: (_) => MediaPickerScreen(
          maxImages: remainingImages,
          videoAllowed: !_hasActiveVideo,
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result.images.isNotEmpty) {
      setState(() => _newImages.addAll(result.images));
    }
    if (result.video != null) {
      await _setNewVideo(result.video!);
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _newImages.add(file));
  }

  Future<void> _setNewVideo(XFile file) async {
    final dir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: dir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    setState(() {
      _newVideo = file;
      _newVideoThumbnailPath = thumbnailPath;
    });
  }

  void _removeExistingMedia(int id) {
    setState(() => _removedMediaIds.add(id));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeNewVideo() {
    setState(() {
      _newVideo = null;
      _newVideoThumbnailPath = null;
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

  // ── 保存 ─────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (_isSaving || _memo == null) return;
    setState(() => _isSaving = true);

    try {
      final distanceText = _distanceController.text;
      final updatedMemo = PracticeMemo(
        id: _memo!.id,
        clubId: _clubId,
        practicedAt: _selectedDate,
        body: _bodyController.text.isEmpty ? null : _bodyController.text,
        condition: _condition,
        distance: distanceText.isEmpty ? null : int.tryParse(distanceText),
        shotShape: _shotShape,
        wind: _wind,
        isFavorite: _memo!.isFavorite,
        createdAt: _memo!.createdAt,
      );
      await _memoRepo.updateMemo(updatedMemo);

      // 削除対象のメディアを処理
      final docsDir = await getApplicationDocumentsDirectory();
      for (final id in _removedMediaIds) {
        final media = _existingMedia.firstWhere((m) => m.id == id);
        await _mediaRepo.deleteMedia(id);
        try {
          await File(MediaPathHelper.resolve(media.uri, docsDir.path)).delete();
          if (media.thumbnailUri != null) {
            await File(MediaPathHelper.resolve(media.thumbnailUri!, docsDir.path)).delete();
          }
        } catch (_) {
          // ファイル削除エラーは無視
        }
      }

      // 新規メディアを保存
      if (_newImages.isNotEmpty || _newVideo != null) {
        final mediaDir = Directory('${docsDir.path}/media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
        }

        final now = DateTime.now();

        for (final image in _newImages) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = image.path.split('.').last.toLowerCase();
          final relPath = 'media/img_$ts.$ext';
          await File(image.path).copy('${mediaDir.path}/img_$ts.$ext');
          await _mediaRepo.insertMedia(Media(
            practiceMemoId: widget.memoId,
            type: 'image',
            uri: relPath,
            createdAt: now,
          ));
        }

        if (_newVideo != null) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = _newVideo!.path.split('.').last.toLowerCase();
          final vidRelPath = 'media/vid_$ts.$ext';
          final vidDestPath = '${mediaDir.path}/vid_$ts.$ext';
          if (await File(_newVideo!.path).length() > 0) {
            await File(_newVideo!.path).copy(vidDestPath);
          }

          String? thumbRelPath;
          if (_newVideoThumbnailPath != null) {
            thumbRelPath = 'media/thumb_$ts.jpg';
            await File(_newVideoThumbnailPath!).copy('${mediaDir.path}/thumb_$ts.jpg');
          }

          await _mediaRepo.insertMedia(Media(
            practiceMemoId: widget.memoId,
            type: 'video',
            uri: vidRelPath,
            thumbnailUri: thumbRelPath,
            createdAt: now,
          ));
        }
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeExistingImages =
        _existingMedia.where((m) => m.isImage && !_removedMediaIds.contains(m.id)).toList();
    final activeExistingVideo =
        _existingMedia.where((m) => m.isVideo && !_removedMediaIds.contains(m.id)).firstOrNull;

    // 未選択セクションのチップ（画面最下部に固定）
    final collapsedChips = <Widget>[
      if (!_openSections.contains('distance'))
        _CollapsedChip(label: '飛距離', onTap: () {
          setState(() => _openSections.add('distance'));
          Future.microtask(() => _distanceFocusNode.requestFocus());
        }),
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
        toolbarHeight: 56 + 8,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            icon: SvgPicture.asset('assets/icons/close.svg', width: 30, height: 30),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 6),
            child: ElevatedButton.icon(
              onPressed: (_isSaving || !_hasChanges) ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              label: Text('保存', style: AppTypography.jpMMedium.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
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
            // ── スクロール部分 ──
            Expanded(
              child: CustomScrollView(
          slivers: [
            // ── 上部固定コンテンツ（日付・クラブ・メディア）──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
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
                              style: AppTypography.jpSubHeader.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            SvgPicture.asset('assets/icons/calendar.svg', width: 20, height: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // クラブ名
                    GestureDetector(
                      onTap: _showClubSelect,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clubName,
                            style: AppTypography.jpHeader1.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset('assets/icons/edit_pen.svg', width: 20, height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // メディアエリア
                    SizedBox(
                      height: 64,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_totalImageCount < AppConstants.maxImagesPerMemo || !_hasActiveVideo)
                            GestureDetector(
                              onTap: _showMediaPicker,
                              child: Container(
                                width: 64,
                                height: 64,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.backgroundMiddle),
                                ),
                                child: Center(
                                  child: SvgPicture.asset('assets/icons/add_photo.svg', width: 28, height: 28),
                                ),
                              ),
                            ),
                          ...activeExistingImages.map((m) {
                            final file = File(MediaPathHelper.resolve(m.uri, _docsPath));
                            return _MediaThumbnail(
                              file: file,
                              onRemove: () => _removeExistingMedia(m.id!),
                              onTap: () => _showPreview(file),
                            );
                          }),
                          if (activeExistingVideo != null)
                            _MediaThumbnail(
                              file: activeExistingVideo.thumbnailUri != null
                                  ? File(MediaPathHelper.resolve(activeExistingVideo.thumbnailUri!, _docsPath))
                                  : null,
                              isVideo: true,
                              onRemove: () => _removeExistingMedia(activeExistingVideo.id!),
                              onTap: () => _showPreview(
                                activeExistingVideo.thumbnailUri != null
                                    ? File(MediaPathHelper.resolve(activeExistingVideo.thumbnailUri!, _docsPath))
                                    : null,
                                isVideo: true,
                                videoPath: MediaPathHelper.resolve(activeExistingVideo.uri, _docsPath),
                              ),
                            ),
                          ..._newImages.asMap().entries.map((entry) {
                            final file = File(entry.value.path);
                            return _MediaThumbnail(
                              file: file,
                              onRemove: () => _removeNewImage(entry.key),
                              onTap: () => _showPreview(file),
                            );
                          }),
                          if (_newVideo != null)
                            _MediaThumbnail(
                              file: _newVideoThumbnailPath != null ? File(_newVideoThumbnailPath!) : null,
                              isVideo: true,
                              onRemove: _removeNewVideo,
                              onTap: () => _showPreview(
                                _newVideoThumbnailPath != null ? File(_newVideoThumbnailPath!) : null,
                                isVideo: true,
                                videoPath: _newVideo?.path,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // ── テキスト（残りの縦スペースをすべて埋める）＋展開セクション ──
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // テキストエリア（縦ストレッチ）
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '練習内容・気づき',
                          hintStyle: AppTypography.jpMRegular.copyWith(color: AppColors.textPlaceholder),
                          border: InputBorder.none,
                        ),
                        style: AppTypography.jpMRegular.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  // 展開セクション（テキストの直下）
                  if (_openSections.contains('distance'))
                    _buildDistanceCard(),
                  if (_openSections.contains('shotShape'))
                    _buildSectionCard(
                      label: '球筋',
                      sectionKey: 'shotShape',
                      child: _ChipSelector(
                        options: AppConstants.shotShapeLabels.entries
                            .map((e) => (value: e.key, label: e.value, svgPath: 'assets/icons/${e.key}.svg'))
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
                            .map((e) => (value: e.key, label: e.value, svgPath: null))
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
                            .map((e) => (value: e.key, label: e.value, svgPath: null))
                            .toList(),
                        selected: _wind,
                        onSelected: (v) => setState(() => _wind = v),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
            ),
            // ── 固定下部（折りたたみチップのみ） ──
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  if (collapsedChips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(children: collapsedChips),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildDistanceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F3F5)),
        ),
        child: Row(
          children: [
            Text('飛距離', style: AppTypography.jpHeader4.copyWith(color: AppColors.textMedium, fontSize: 14)),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _distanceController,
                focusNode: _distanceFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('yd', style: AppTypography.enMMedium.copyWith(color: AppColors.textPlaceholder)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => setState(() => _openSections.remove('distance')),
              child: const Icon(Icons.close, size: 20, color: AppColors.textMedium),
            ),
          ],
        ),
      ),
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
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.only(left: 4, right: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundMiddle,
          borderRadius: BorderRadius.circular(24),
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
// クラブ選択シート
// ──────────────────────────────────────────────────────
class _ClubSelectSheet extends StatefulWidget {
  final void Function(int clubId, String clubName) onClubSelected;
  final VoidCallback? onOpenSettings;

  const _ClubSelectSheet({
    required this.onClubSelected,
    this.onOpenSettings,
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
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _clubGroups.length + 2,
                itemBuilder: (context, index) {
                  // ドラッグインジケーター + ヘッダー
                  if (index == 0) {
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Text(
                                'クラブを選択',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
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
                      ],
                    );
                  }

                  // 設定画面への動線
                  if (index == _clubGroups.length + 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: GestureDetector(
                        onTap: widget.onOpenSettings,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'クラブの設定を開く',
                              style: TextStyle(fontSize: 14, color: Colors.blue),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_outward, size: 14, color: Colors.blue),
                          ],
                        ),
                      ),
                    );
                  }

                  // クラブグループ
                  final group = _clubGroups[index - 1];
                  final clubs = group['clubs'] as List<Club>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 6, left: 4),
                        child: Text(
                          group['category'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: List.generate(clubs.length, (i) {
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 2,
                                  ),
                                  title: Text(
                                    clubs[i].name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  onTap: () =>
                                      widget.onClubSelected(clubs[i].id!, clubs[i].name),
                                ),
                                if (i < clubs.length - 1)
                                  const Divider(
                                    height: 0.5,
                                    indent: 16,
                                    color: AppColors.divider,
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// チップ選択（球筋・調子・風で共通）
// ──────────────────────────────────────────────────────
class _ChipSelector extends StatelessWidget {
  final List<({String value, String label, String? svgPath})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool useGridLayout;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.useGridLayout = false,
  });

  Widget _buildChip(({String value, String label, String? svgPath}) opt, {bool compact = false}) {
    final isSelected = selected == opt.value;
    return GestureDetector(
      onTap: () => onSelected(isSelected ? null : opt.value),
      child: Container(
        padding: compact
            ? const EdgeInsets.fromLTRB(4, 8, 4, 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD0D7DE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (opt.svgPath != null) ...[
              SvgPicture.asset(
                opt.svgPath!,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : AppColors.textPlaceholder,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: Text(
                opt.label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.jpMMedium.copyWith(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textPlaceholder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useGridLayout && options.length == 5) {
      // 3＋2のグリッドレイアウト（球筋用）
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildChip(options[0], compact: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildChip(options[1], compact: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildChip(options[2], compact: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildChip(options[3], compact: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildChip(options[4], compact: true)),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((opt) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: _buildChip(opt),
            );
          }).toList(),
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
              borderRadius: BorderRadius.circular(8),
              color: AppColors.divider,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file != null
                  ? Image.file(file!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.videocam, size: 28, color: AppColors.textSecondary),
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
          top: -8,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
