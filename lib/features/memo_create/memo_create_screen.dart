import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

// ──────────────────────────────────────────────────────
// ルート：ローカルNavigatorでクラブ選択→フォームを管理
// ──────────────────────────────────────────────────────
class MemoCreateScreen extends StatelessWidget {
  const MemoCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // go_routerのコンテキストをここで保持
    final outerContext = context;

    return Navigator(
      onGenerateRoute: (_) => CupertinoPageRoute(
        builder: (ctx) => _ClubSelectPage(
          onClose: () => outerContext.pop(),
          onClubSelected: (name) {
            Navigator.of(ctx).push(
              CupertinoPageRoute(
                builder: (_) => _MemoInputPage(
                  clubName: name,
                  onSave: () => outerContext.go('/home'), // TODO: DBに保存
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
// クラブ選択ページ
// ──────────────────────────────────────────────────────
class _ClubSelectPage extends StatelessWidget {
  final ValueChanged<String> onClubSelected;
  final VoidCallback onClose;

  const _ClubSelectPage({
    required this.onClubSelected,
    required this.onClose,
  });

  // ダミーデータ（後でDBから取得）
  static const _clubGroups = [
    {'category': 'ウッド',         'clubs': ['ドライバー', '3W', '5W']},
    {'category': 'ユーティリティ', 'clubs': ['3U', '4U', '5U']},
    {'category': 'アイアン',       'clubs': ['5I', '6I', '7I', '8I', '9I']},
    {'category': 'ウェッジ',       'clubs': ['PW', 'AW', 'SW']},
    {'category': 'その他',         'clubs': ['パター']},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // ドラッグバー(1) + ヘッダー(1) + カテゴリ数 + 設定リンク(1)
          itemCount: _clubGroups.length + 3,
          itemBuilder: (context, index) {
            // ドラッグインジケーター
            if (index == 0) {
              return const Center(child: _DragIndicator());
            }

            // ヘッダー（× ボタン + タイトル）
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
                        onTap: onClose,
                        child: const Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 一番下：設定画面への動線
            if (index == _clubGroups.length + 2) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: GestureDetector(
                  onTap: () {
                    onClose();
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

            // クラブグループ（カテゴリ + クラブ一覧）
            final group = _clubGroups[index - 2];
            final clubs = group['clubs'] as List<String>;

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
                              clubs[i],
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            onTap: () => onClubSelected(clubs[i]),
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
  final String clubName;
  final VoidCallback onSave;

  const _MemoInputPage({
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
                // modalContext を使うことでモーダルだけを閉じる
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

  @override
  Widget build(BuildContext context) {
    final visibleItems = _showAllItems
        ? ['distance', 'shotShape', 'condition', 'wind']
        : ['distance', 'shotShape'];

    return Scaffold(
      backgroundColor: Colors.white,
      // 保存ボタンをbottomに固定することでスクロールエリアが常に全体を使える
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
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
                    // 戻るボタン
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                    ),
                    // クラブ名
                    Text(
                      widget.clubName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 日付 + カレンダーアイコン
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
                    // 画像追加ボタン
                    Container(
                      width: 56,
                      height: 56,
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
                    const SizedBox(height: 20),
                    // メモ入力
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
                    // オプション項目
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
      'distance': (Icons.place_outlined,              '飛距離'),
      'shotShape': (Icons.north_east,                 '球筋'),
      'condition': (Icons.sentiment_satisfied_outlined, '調子'),
      'wind':      (Icons.air,                        '風'),
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
                Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                ),
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
