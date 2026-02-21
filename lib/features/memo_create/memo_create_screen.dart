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
          onClose: () => outerContext.pop(),
          onClubSelected: (int clubId, String clubName) {
            Navigator.of(ctx).push(
              CupertinoPageRoute(
                builder: (_) => _MemoInputPage(
                  clubId: clubId,
                  clubName: clubName,
                  onSave: () => outerContext.go('/home'),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _clubGroups.length + 3,
          itemBuilder: (context, index) {
            // ドラッグインジケーター
            if (index == 0) {
              return const Center(child: _DragIndicator());
            }

            // ヘッダー
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 設定画面への動線
            if (index == _clubGroups.length + 2) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: GestureDetector(
                  onTap: () {
                    widget.onClose();
                    Future.microtask(() => context.push('/settings'));
                  },
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
            final group = _clubGroups[index - 2];
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
                            onTap: () => widget.onClubSelected(clubs[i].id!, clubs[i].name),
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
  DateTime _selectedDate = DateTime.now();
  final _bodyController = TextEditingController();

  bool _showAllItems = false;
  final Set<String> _expandedItems = {};

  String? _distance;
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
  void dispose() {
    _bodyController.dispose();
    super.dispose();
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

  void _showMediaPicker() {
    if (_images.length >= AppConstants.maxImagesPerMemo && _video != null) return;

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
              _showCameraSheet();
            },
            child: const Text('写真を撮る'),
          ),
          if (_video == null)
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

  void _showCameraSheet() {
    _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromLibrary() async {
    final file = await _picker.pickMedia();
    if (file == null) return;

    if (_isVideoFile(file)) {
      if (_video != null) return;
      await _setVideo(file);
    } else {
      if (_images.length >= AppConstants.maxImagesPerMemo) return;
      setState(() => _images.add(file));
    }
  }

  bool _isVideoFile(XFile file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
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
      _video = XFile(dummyFile.path);
      _videoThumbnailPath = null;
    });
  }

  // ── DB保存 ───────────────────────────────────────────

  Future<void> _saveMemo() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      // メモ保存
      final memo = PracticeMemo(
        clubId: widget.clubId,
        practicedAt: _selectedDate,
        body: _bodyController.text.isEmpty ? null : _bodyController.text,
        condition: _condition,
        distance: int.tryParse(_distance ?? ''),
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
          final destPath = '${mediaDir.path}/img_$ts.$ext';
          await File(image.path).copy(destPath);
          await _mediaRepo.insertMedia(Media(
            practiceMemoId: savedMemo.id!,
            type: 'image',
            uri: destPath,
            createdAt: now,
          ));
        }

        if (_video != null) {
          final ts = DateTime.now().microsecondsSinceEpoch;
          final ext = _video!.path.split('.').last.toLowerCase();
          final vidDestPath = '${mediaDir.path}/vid_$ts.$ext';
          // ダミーファイル（空）の場合はコピーしない
          if (await File(_video!.path).length() > 0) {
            await File(_video!.path).copy(vidDestPath);
          }

          String? thumbDestPath;
          if (_videoThumbnailPath != null) {
            thumbDestPath = '${mediaDir.path}/thumb_$ts.jpg';
            await File(_videoThumbnailPath!).copy(thumbDestPath);
          }

          await _mediaRepo.insertMedia(Media(
            practiceMemoId: savedMemo.id!,
            type: 'video',
            uri: vidDestPath,
            thumbnailUri: thumbDestPath,
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
    final visibleItems = _showAllItems
        ? ['distance', 'shotShape', 'condition', 'wind']
        : ['distance', 'shotShape'];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveMemo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
        child: Column(
          children: [
            const _DragIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      widget.clubName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    // メディアエリア（追加ボタン左固定）
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_images.length < AppConstants.maxImagesPerMemo ||
                              _video == null)
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
                          ..._images.asMap().entries.map((entry) {
                            final file = File(entry.value.path);
                            return _MediaThumbnail(
                              file: file,
                              onRemove: () => _removeImage(entry.key),
                              onTap: () => _showPreview(file),
                            );
                          }),
                          if (_video != null)
                            _MediaThumbnail(
                              file: _videoThumbnailPath != null
                                  ? File(_videoThumbnailPath!)
                                  : null,
                              isVideo: true,
                              onRemove: _removeVideo,
                              onTap: () => _showPreview(
                                _videoThumbnailPath != null
                                    ? File(_videoThumbnailPath!)
                                    : null,
                                isVideo: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
          ],
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
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (v) => setState(() => _distance = v),
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

// ──────────────────────────────────────────────────────
// ドラッグインジケーター
// ──────────────────────────────────────────────────────
class _DragIndicator extends StatelessWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
