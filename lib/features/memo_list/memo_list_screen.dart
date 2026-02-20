import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/memo_card.dart';

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: const Text(
            'メモ一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.primary),
              onPressed: () => context.push('/search'),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'すべて'),
              Tab(text: 'お気に入り'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AllMemosTab(),
            _FavoriteMemosTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/memo/create'),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 8,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 記録一覧（現在の画面）
                IconButton(
                  icon: const Icon(Icons.list_alt_outlined),
                  color: AppColors.primary,
                  onPressed: () {},
                ),
                const SizedBox(width: 48), // FABのスペース
                // レポート
                IconButton(
                  icon: const Icon(Icons.trending_up_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () => context.push('/report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── すべてのメモ一覧 ──────────────────────────────────
class _AllMemosTab extends StatelessWidget {
  const _AllMemosTab();

  @override
  Widget build(BuildContext context) {
    // ※ 後でデータベースから実際のデータを取得します
    // 現時点はレイアウト確認用のダミーデータです
    final dummyGroups = [
      {
        'date': '1/12  金  2026',
        'memos': [
          {'club': 'ドライバー', 'distance': '270yd', 'body': 'ソールをまず地面につけた後、ちょっと浮かして構える！'},
          {'club': '5W',        'distance': '220yd', 'body': '軸に乗せて、少し大きくテークバックしてハーフのつもりで振る。'},
          {'club': '7I',        'distance': '160yd', 'body': '軸に乗せて、少し大きくテークバックしてハーフのつもりで振る。'},
          {'club': '52°',       'distance': '30yd',  'body': null},
        ],
      },
      {
        'date': '1/4  木  2026',
        'memos': [
          {'club': 'ドライバー', 'distance': '270yd', 'body': 'ソールをまず地面につけた後、ちょっと浮かして構える！'},
          {'club': '5W',        'distance': '220yd', 'body': '軸に乗せて、少し大きくテークバックしてハーフのつもりで振る。'},
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: dummyGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = dummyGroups[groupIndex];
        final memos = group['memos'] as List;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付ヘッダー
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
              child: Text(
                group['date'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // カード一覧
            ...memos.map((memo) {
              final m = memo as Map<String, dynamic>;
              return MemoCard(
                clubName: m['club'] as String,
                distance: m['distance'] as String?,
                bodyText: m['body'] as String?,
                onTap: () => context.push('/memo/1'),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── お気に入り一覧 ────────────────────────────────────
class _FavoriteMemosTab extends StatelessWidget {
  const _FavoriteMemosTab();

  @override
  Widget build(BuildContext context) {
    // ※ 後でデータベースから実際のデータを取得します
    final dummyFavorites = [
      {'date': '2026/1/12（金）',  'club': 'ドライバー', 'distance': '270yd', 'body': 'ソールをまず地面につけた後、ちょっと浮かして構える！'},
      {'date': '2026/1/4（木）',   'club': 'ドライバー', 'distance': '270yd', 'body': 'ソールをまず地面につけた後、ちょっと浮かして構える！'},
      {'date': '2025/12/24（水）', 'club': 'ドライバー', 'distance': '270yd', 'body': 'ソールをまず地面につけた後、ちょっと浮かして構える！'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: dummyFavorites.length,
      itemBuilder: (context, index) {
        final item = dummyFavorites[index];
        return _FavoriteMemoCard(
          date: item['date']!,
          clubName: item['club']!,
          distance: item['distance'],
          bodyText: item['body'],
          onTap: () => context.push('/memo/1'),
        );
      },
    );
  }
}

// お気に入りタブ用カード（日付がカード内に表示される）
class _FavoriteMemoCard extends StatelessWidget {
  final String date;
  final String clubName;
  final String? distance;
  final String? bodyText;
  final VoidCallback onTap;

  const _FavoriteMemoCard({
    required this.date,
    required this.clubName,
    this.distance,
    this.bodyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            // クラブ名 + インジケーター + 距離
            Row(
              children: [
                Text(
                  clubName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                if (distance != null)
                  Text(
                    distance!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            // メモ本文
            if (bodyText != null) ...[
              const SizedBox(height: 4),
              Text(
                bodyText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
