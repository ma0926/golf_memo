import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:golf_memo/data/models/practice_memo.dart';
import 'package:golf_memo/data/database/database_helper.dart';
import 'package:golf_memo/data/repositories/practice_memo_repository.dart';

// テスト用にインメモリDBをセットアップし、DatabaseHelper のシングルトンに注入する
Future<void> _setupTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // シングルトンの内部状態をリセット
  DatabaseHelper.resetForTest();

  // インメモリ DB を開いて DatabaseHelper に注入する
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    ),
  );
  DatabaseHelper.injectDatabaseForTest(db);
}

Future<void> _createTables(Database db) async {
  await db.execute('''
    CREATE TABLE clubs (
      club_id     INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      category    TEXT    NOT NULL,
      sort_order  INTEGER NOT NULL,
      is_active   INTEGER NOT NULL DEFAULT 1,
      is_custom   INTEGER NOT NULL DEFAULT 0,
      master_id   TEXT,
      created_at  TEXT    NOT NULL,
      deleted_at  TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE practice_memos (
      practice_memo_id  INTEGER PRIMARY KEY AUTOINCREMENT,
      club_id           INTEGER NOT NULL,
      practiced_at      TEXT    NOT NULL,
      body              TEXT,
      condition         TEXT,
      distance          INTEGER,
      shot_shape        TEXT,
      wind              TEXT,
      is_favorite       INTEGER NOT NULL DEFAULT 0,
      created_at        TEXT    NOT NULL,
      FOREIGN KEY (club_id) REFERENCES clubs (club_id)
    )
  ''');

  await db.execute('''
    CREATE TABLE media (
      media_id          INTEGER PRIMARY KEY AUTOINCREMENT,
      practice_memo_id  INTEGER NOT NULL,
      type              TEXT    NOT NULL,
      uri               TEXT    NOT NULL,
      thumbnail_uri     TEXT,
      created_at        TEXT    NOT NULL,
      FOREIGN KEY (practice_memo_id) REFERENCES practice_memos (practice_memo_id)
    )
  ''');

  // テスト用ダミークラブを1件挿入（ForeignKey制約を満たすため）
  await db.insert('clubs', {
    'name': 'テストクラブ',
    'category': 'アイアン',
    'sort_order': 1,
    'is_active': 1,
    'is_custom': 0,
    'created_at': DateTime.now().toIso8601String(),
  });
}

void main() {
  late PracticeMemoRepository repo;

  setUp(() async {
    await _setupTestDatabase();
    repo = PracticeMemoRepository();
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
    DatabaseHelper.resetForTest();
  });

  group('PracticeMemoRepository CRUD テスト', () {
    // テスト用メモのファクトリ
    PracticeMemo _createMemo({
      int clubId = 1,
      String? body,
      String condition = 'good',
      int distance = 200,
      bool isFavorite = false,
      DateTime? practicedAt,
    }) {
      return PracticeMemo(
        clubId: clubId,
        practicedAt: practicedAt ?? DateTime(2025, 6, 1),
        body: body,
        condition: condition,
        distance: distance,
        shotShape: 'straight',
        wind: 'normal',
        isFavorite: isFavorite,
        createdAt: DateTime.now(),
      );
    }

    // ──────────────────────────────────────────
    // INSERT
    // ──────────────────────────────────────────
    group('insertMemo', () {
      test('メモを1件挿入すると id が付与されて返ってくる', () async {
        final memo = _createMemo(body: '挿入テスト');
        final inserted = await repo.insertMemo(memo);

        expect(inserted.id, isNotNull);
        expect(inserted.body, '挿入テスト');
        // 実際に DB に保存されているか確認
        final found = await repo.getMemoById(inserted.id!);
        expect(found, isNotNull);
        expect(found!.body, '挿入テスト');
      });

      test('複数件挿入すると異なる id が付与される', () async {
        final m1 = await repo.insertMemo(_createMemo(body: 'メモ1'));
        final m2 = await repo.insertMemo(_createMemo(body: 'メモ2'));

        expect(m1.id, isNot(m2.id));
      });
    });

    // ──────────────────────────────────────────
    // SELECT
    // ──────────────────────────────────────────
    group('getAllMemos', () {
      test('挿入した件数だけ取得できる', () async {
        await repo.insertMemo(_createMemo(body: 'A'));
        await repo.insertMemo(_createMemo(body: 'B'));
        await repo.insertMemo(_createMemo(body: 'C'));

        final memos = await repo.getAllMemos();
        expect(memos.length, 3);
      });

      test('practiced_at の降順で返ってくる', () async {
        await repo.insertMemo(_createMemo(body: '古い', practicedAt: DateTime(2025, 1, 1)));
        await repo.insertMemo(_createMemo(body: '新しい', practicedAt: DateTime(2025, 6, 1)));

        final memos = await repo.getAllMemos();
        expect(memos.first.body, '新しい');
        expect(memos.last.body, '古い');
      });
    });

    group('getMemoById', () {
      test('存在する id で1件取得できる', () async {
        final inserted = await repo.insertMemo(_createMemo(body: 'ID取得テスト'));
        final found = await repo.getMemoById(inserted.id!);

        expect(found, isNotNull);
        expect(found!.body, 'ID取得テスト');
      });

      test('存在しない id は null を返す', () async {
        final found = await repo.getMemoById(99999);
        expect(found, isNull);
      });
    });

    group('getFavoriteMemos', () {
      test('お気に入りのみが返ってくる', () async {
        await repo.insertMemo(_createMemo(body: '普通', isFavorite: false));
        await repo.insertMemo(_createMemo(body: 'お気に入り', isFavorite: true));

        final favorites = await repo.getFavoriteMemos();
        expect(favorites.length, 1);
        expect(favorites.first.body, 'お気に入り');
        expect(favorites.first.isFavorite, true);
      });
    });

    // ──────────────────────────────────────────
    // UPDATE
    // ──────────────────────────────────────────
    group('updateMemo', () {
      test('フィールドを更新すると DB に反映される', () async {
        final inserted = await repo.insertMemo(_createMemo(body: '更新前'));
        final updated = inserted.copyWith(body: '更新後', distance: 999);

        await repo.updateMemo(updated);

        final found = await repo.getMemoById(inserted.id!);
        expect(found!.body, '更新後');
        expect(found.distance, 999);
      });
    });

    group('toggleFavorite', () {
      test('false → true に切り替えられる', () async {
        final inserted = await repo.insertMemo(_createMemo(isFavorite: false));
        await repo.toggleFavorite(inserted.id!, true);

        final found = await repo.getMemoById(inserted.id!);
        expect(found!.isFavorite, true);
      });

      test('true → false に切り替えられる', () async {
        final inserted = await repo.insertMemo(_createMemo(isFavorite: true));
        await repo.toggleFavorite(inserted.id!, false);

        final found = await repo.getMemoById(inserted.id!);
        expect(found!.isFavorite, false);
      });
    });

    // ──────────────────────────────────────────
    // DELETE
    // ──────────────────────────────────────────
    group('deleteMemo', () {
      test('削除すると getMemoById で null が返る', () async {
        final inserted = await repo.insertMemo(_createMemo(body: '削除テスト'));
        await repo.deleteMemo(inserted.id!);

        final found = await repo.getMemoById(inserted.id!);
        expect(found, isNull);
      });

      test('削除後、残りの件数が1件減る', () async {
        final m1 = await repo.insertMemo(_createMemo(body: 'keep'));
        final m2 = await repo.insertMemo(_createMemo(body: 'delete'));

        await repo.deleteMemo(m2.id!);

        final all = await repo.getAllMemos();
        expect(all.length, 1);
        expect(all.first.id, m1.id);
      });
    });

    // ──────────────────────────────────────────
    // SEARCH / FILTER
    // ──────────────────────────────────────────
    group('searchMemos', () {
      setUp(() async {
        await repo.insertMemo(_createMemo(body: 'ドローが出た', condition: 'good', distance: 250, isFavorite: true));
        await repo.insertMemo(_createMemo(body: 'スライスした', condition: 'bad', distance: 180, isFavorite: false));
        await repo.insertMemo(_createMemo(body: null, condition: 'normal', distance: 200, isFavorite: false));
      });

      test('keyword 検索でマッチするものだけ返ってくる', () async {
        final results = await repo.searchMemos(keyword: 'ドロー');
        expect(results.length, 1);
        expect(results.first.body, 'ドローが出た');
      });

      test('condition フィルターが機能する', () async {
        final results = await repo.searchMemos(condition: 'bad');
        expect(results.length, 1);
        expect(results.first.condition, 'bad');
      });

      test('isFavorite=true フィルターが機能する', () async {
        final results = await repo.searchMemos(isFavorite: true);
        expect(results.length, 1);
        expect(results.first.isFavorite, true);
      });

      test('distanceMin/Max フィルターが機能する', () async {
        final results = await repo.searchMemos(distanceMin: 200, distanceMax: 260);
        expect(results.length, 2); // 250, 200
        for (final m in results) {
          expect(m.distance! >= 200, true);
          expect(m.distance! <= 260, true);
        }
      });

      test('条件なしで全件返ってくる', () async {
        final results = await repo.searchMemos();
        expect(results.length, 3);
      });
    });

    // ──────────────────────────────────────────
    // getMemosByDateRange
    // ──────────────────────────────────────────
    group('getMemosByDateRange', () {
      test('日付範囲内のメモだけが返ってくる', () async {
        await repo.insertMemo(_createMemo(body: '範囲内', practicedAt: DateTime(2025, 3, 15)));
        await repo.insertMemo(_createMemo(body: '範囲外', practicedAt: DateTime(2025, 7, 1)));

        final results = await repo.getMemosByDateRange(
          from: DateTime(2025, 1, 1),
          to: DateTime(2025, 6, 30),
        );

        expect(results.length, 1);
        expect(results.first.body, '範囲内');
      });
    });
  });
}
