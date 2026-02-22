import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/club.dart';
import '../../data/models/media.dart';
import '../../data/models/practice_memo.dart';
import '../../data/repositories/club_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/practice_memo_repository.dart';
import '../../shared/widgets/media_preview_screen.dart';

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

  bool _showAllItems = false;
  final Set<String> _expandedItems = {};

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final memo = await _memoRepo.getMemoById(widget.memoId);
    if (memo == null) {
      if (mounted) context.pop();
      return;
    }
    final club = await _clubRepo.getClubById(memo.clubId);
    final media = await _mediaRepo.getMediaByMemoId(widget.memoId);

    final expandedItems = <String>{};
    if (memo.distance != null) expandedItems.add('distance');
    if (memo.shotShape != null) expandedItems.add('shotShape');
    if (memo.condition != null) expandedItems.add('condition');
    if (memo.wind != null) expandedItems.add('wind');

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
      _expandedItems.addAll(expandedItems);
      if (memo.condition != null || memo.wind != null) {
        _showAllItems = true;
      }
      _isLoading = false;
    });
  }

  String get _formattedDate {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekdays[_selectedDate.weekday - 1];
    return '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}（$w）';
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
                child: const Text('完了'),
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

  void _toggleExpand(String key) {
    setState(() {
      if (_expandedItems.contains(key)) {
        _expandedItems.remove(key);
      } else {
        _expandedItems.add(key);
      }
    });
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

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickFromLibrary();
            },
            child: const Text('ライブラリから選ぶ'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text('写真を撮る'),
          ),
          if (!_hasActiveVideo)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _setDummyVideo();
              },
              child: const Text('【開発用】ダミー動画を追加'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  Future<void> _pickFromLibrary() async {
    final file = await _picker.pickMedia();
    if (file == null) return;

    if (_isVideoFile(file)) {
      if (_hasActiveVideo) return;
      await _setNewVideo(file);
    } else {
      if (_totalImageCount >= AppConstants.maxImagesPerMemo) return;
      setState(() => _newImages.add(file));
    }
  }

  bool _isVideoFile(XFile file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
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

  void _showPreview(File? file, {bool isVideo = false}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(file: file, isVideo: isVideo),
      ),
    );
  }

  Future<void> _setDummyVideo() async {
    final dir = await getTemporaryDirectory();
    final dummyFile = File('${dir.path}/dummy_video.mp4');
    await dummyFile.writeAsBytes([]);
    setState(() {
      _newVideo = XFile(dummyFile.path);
      _newVideoThumbnailPath = null;
    });
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
      for (final id in _removedMediaIds) {
        final media = _existingMedia.firstWhere((m) => m.id == id);
        await _mediaRepo.deleteMedia(id);
        try {
          await File(media.uri).delete();
          if (media.thumbnailUri != null) {
            await File(media.thumbnailUri!).delete();
          }
        } catch (_) {
          // ファイル削除エラーは無視
        }
      }

      // 新規メディアを保存
      if (_newImages.isNotEmpty || _newVideo != null) {
        final docsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory('${docsDir.path}/media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
        }

        final now = DateTime.now();

        for (final image in _newImages) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = image.path.split('.').last.toLowerCase();
          final destPath = '${mediaDir.path}/img_$ts.$ext';
          await File(image.path).copy(destPath);
          await _mediaRepo.insertMedia(Media(
            practiceMemoId: widget.memoId,
            type: 'image',
            uri: destPath,
            createdAt: now,
          ));
        }

        if (_newVideo != null) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = _newVideo!.path.split('.').last.toLowerCase();
          final vidDestPath = '${mediaDir.path}/vid_$ts.$ext';
          if (await File(_newVideo!.path).length() > 0) {
            await File(_newVideo!.path).copy(vidDestPath);
          }

          String? thumbDestPath;
          if (_newVideoThumbnailPath != null) {
            thumbDestPath = '${mediaDir.path}/thumb_$ts.jpg';
            await File(_newVideoThumbnailPath!).copy(thumbDestPath);
          }

          await _mediaRepo.insertMedia(Media(
            practiceMemoId: widget.memoId,
            type: 'video',
            uri: vidDestPath,
            thumbnailUri: thumbDestPath,
            createdAt: now,
          ));
        }
      }

      if (mounted) context.pop(true);
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

    final visibleItems = _showAllItems
        ? ['distance', 'shotShape', 'condition', 'wind']
        : ['distance', 'shotShape'];

    final activeExistingImages =
        _existingMedia.where((m) => m.isImage && !_removedMediaIds.contains(m.id)).toList();
    final activeExistingVideo =
        _existingMedia.where((m) => m.isVideo && !_removedMediaIds.contains(m.id)).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '編集',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // クラブ名（タップでクラブ選択）
              GestureDetector(
                onTap: _showClubSelect,
                child: Row(
                  children: [
                    Text(
                      _clubName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 日付
              GestureDetector(
                onTap: _showDatePicker,
                child: Row(
                  children: [
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // メディアエリア
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_totalImageCount < AppConstants.maxImagesPerMemo || !_hasActiveVideo)
                      GestureDetector(
                        onTap: _showMediaPicker,
                        child: Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    // 既存画像（アクティブ）
                    ...activeExistingImages.map((m) {
                      final file = File(m.uri);
                      return _MediaThumbnail(
                        file: file,
                        onRemove: () => _removeExistingMedia(m.id!),
                        onTap: () => _showPreview(file),
                      );
                    }),
                    // 既存動画（アクティブ）
                    if (activeExistingVideo != null)
                      _MediaThumbnail(
                        file: activeExistingVideo.thumbnailUri != null
                            ? File(activeExistingVideo.thumbnailUri!)
                            : null,
                        isVideo: true,
                        onRemove: () => _removeExistingMedia(activeExistingVideo.id!),
                        onTap: () => _showPreview(
                          activeExistingVideo.thumbnailUri != null
                              ? File(activeExistingVideo.thumbnailUri!)
                              : null,
                          isVideo: true,
                        ),
                      ),
                    // 新規画像
                    ..._newImages.asMap().entries.map((entry) {
                      final file = File(entry.value.path);
                      return _MediaThumbnail(
                        file: file,
                        onRemove: () => _removeNewImage(entry.key),
                        onTap: () => _showPreview(file),
                      );
                    }),
                    // 新規動画
                    if (_newVideo != null)
                      _MediaThumbnail(
                        file: _newVideoThumbnailPath != null
                            ? File(_newVideoThumbnailPath!)
                            : null,
                        isVideo: true,
                        onRemove: _removeNewVideo,
                        onTap: () => _showPreview(
                          _newVideoThumbnailPath != null
                              ? File(_newVideoThumbnailPath!)
                              : null,
                          isVideo: true,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // メモ本文
              TextField(
                controller: _bodyController,
                maxLines: null,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'どんなことを意識した？',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider),
              ...visibleItems.map((key) => _buildOptionalItem(key)),
              if (!_showAllItems)
                InkWell(
                  onTap: () => setState(() => _showAllItems = true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text(
                          'すべて表示',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalItem(String key) {
    final isExpanded = _expandedItems.contains(key);

    final configs = {
      'distance':  (Icons.place_outlined,               '飛距離'),
      'shotShape': (Icons.north_east,                   '球筋'),
      'condition': (Icons.sentiment_satisfied_outlined,  '調子'),
      'wind':      (Icons.air,                           '風'),
    };

    final (icon, label) = configs[key]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleExpand(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                const Spacer(),
                if (isExpanded)
                  const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildExpandedContent(key),
      ],
    );
  }

  Widget _buildExpandedContent(String key) {
    switch (key) {
      case 'distance':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('yd', style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      case 'shotShape':
        return _ChipSelector(
          options: AppConstants.shotShapeLabels.entries
              .map((e) => (value: e.key, label: e.value))
              .toList(),
          selected: _shotShape,
          onSelected: (v) => setState(() => _shotShape = v),
        );
      case 'condition':
        return _ChipSelector(
          options: AppConstants.conditionLabels.entries
              .map((e) => (value: e.key, label: e.value))
              .toList(),
          selected: _condition,
          onSelected: (v) => setState(() => _condition = v),
        );
      case 'wind':
        return _ChipSelector(
          options: AppConstants.windLabels.entries
              .map((e) => (value: e.key, label: e.value))
              .toList(),
          selected: _wind,
          onSelected: (v) => setState(() => _wind = v),
        );
      default:
        return const SizedBox.shrink();
    }
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
  final List<({String value, String label})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = selected == opt.value;
          return GestureDetector(
            onTap: () => onSelected(isSelected ? null : opt.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
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
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.divider,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
