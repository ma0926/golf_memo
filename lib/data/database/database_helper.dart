import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseHelper._();

  Future<Database> get database {
    // 同時に複数の呼び出しが来ても _initDatabase() は1回しか実行しない
    _initFuture ??= _initDatabase();
    return _initFuture!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'golf_memo.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultClubs(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // クラブテーブル
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

    // 練習記録テーブル
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

    // メディアテーブル
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
  }

  // v1 → v2 マイグレーション
  Future<void> _migrateV1ToV2(Database db) async {
    final now = DateTime.now().toIso8601String();

    // ── 既存クラブの名前・並び順・ON/OFFを更新 ──────────────
    final updates = [
      // [旧名前, 新名前, 新sort_order, 新is_active]
      ['ドライバー',  'ドライバー',                     1,  1],
      ['3W',         '3番ウッド',                       2,  1],
      ['5W',         '5番ウッド',                       3,  1],
      ['3U',         '3番ユーティリティ',               8,  1],
      ['4U',         '4番ユーティリティ',               9,  1],
      ['5I',         '5番アイアン',                     16, 0],
      ['6I',         '6番アイアン',                     17, 1],
      ['7I',         '7番アイアン',                     18, 1],
      ['8I',         '8番アイアン',                     19, 1],
      ['9I',         '9番アイアン',                     20, 1],
      ['PW',         'ピッチングウェッジ（44〜47°）',   21, 1],
      ['AW',         'アプローチウェッジ（48〜53°）',   22, 1],
      ['SW',         'サンドウェッジ（54〜58°）',       23, 0],
      ['パター',     'パター',                           25, 0],
    ];

    for (final u in updates) {
      await db.execute(
        'UPDATE clubs SET name = ?, sort_order = ?, is_active = ? WHERE name = ? AND is_custom = 0',
        [u[1], u[2], u[3], u[0]],
      );
    }

    // ── 不足しているクラブを追加 ──────────────────────────
    final newClubs = [
      {'name': '7番ウッド',                      'category': 'ウッド',         'sort_order': 4,  'is_active': 0},
      {'name': '9番ウッド',                      'category': 'ウッド',         'sort_order': 5,  'is_active': 0},
      {'name': '11番ウッド',                     'category': 'ウッド',         'sort_order': 6,  'is_active': 0},
      {'name': '2番ユーティリティ',              'category': 'ユーティリティ', 'sort_order': 7,  'is_active': 0},
      {'name': '5番ユーティリティ',              'category': 'ユーティリティ', 'sort_order': 10, 'is_active': 1},
      {'name': '6番ユーティリティ',              'category': 'ユーティリティ', 'sort_order': 11, 'is_active': 1},
      {'name': '1番アイアン',                    'category': 'アイアン',       'sort_order': 12, 'is_active': 0},
      {'name': '2番アイアン',                    'category': 'アイアン',       'sort_order': 13, 'is_active': 0},
      {'name': '3番アイアン',                    'category': 'アイアン',       'sort_order': 14, 'is_active': 0},
      {'name': '4番アイアン',                    'category': 'アイアン',       'sort_order': 15, 'is_active': 0},
      {'name': 'ロブウェッジ（58〜64°）',        'category': 'ウェッジ',       'sort_order': 24, 'is_active': 0},
    ];

    for (final club in newClubs) {
      final existing = await db.query(
        'clubs',
        where: 'name = ? AND is_custom = 0',
        whereArgs: [club['name']],
      );
      if (existing.isEmpty) {
        await db.insert('clubs', {
          ...club,
          'is_custom': 0,
          'created_at': now,
        });
      }
    }
  }

  // v2 → v3 マイグレーション
  // master_id カラムを追加し、全デフォルトクラブに固定IDをセットする
  Future<void> _migrateV2ToV3(Database db) async {
    // カラム追加
    await db.execute('ALTER TABLE clubs ADD COLUMN master_id TEXT');

    // デフォルトクラブに master_id をセット
    // [name, master_id]
    final masterIds = [
      ['ドライバー',                    'driver'],
      ['3番ウッド',                     'wood_3'],
      ['5番ウッド',                     'wood_5'],
      ['7番ウッド',                     'wood_7'],
      ['9番ウッド',                     'wood_9'],
      ['11番ウッド',                    'wood_11'],
      ['2番ユーティリティ',             'ut_2'],
      ['3番ユーティリティ',             'ut_3'],
      ['4番ユーティリティ',             'ut_4'],
      ['5番ユーティリティ',             'ut_5'],
      ['6番ユーティリティ',             'ut_6'],
      ['1番アイアン',                   'iron_1'],
      ['2番アイアン',                   'iron_2'],
      ['3番アイアン',                   'iron_3'],
      ['4番アイアン',                   'iron_4'],
      ['5番アイアン',                   'iron_5'],
      ['6番アイアン',                   'iron_6'],
      ['7番アイアン',                   'iron_7'],
      ['8番アイアン',                   'iron_8'],
      ['9番アイアン',                   'iron_9'],
      ['ピッチングウェッジ（44〜47°）', 'wedge_pw'],
      ['アプローチウェッジ（48〜53°）', 'wedge_aw'],
      ['サンドウェッジ（54〜58°）',     'wedge_sw'],
      ['ロブウェッジ（58〜64°）',       'wedge_lw'],
      ['パター',                        'putter'],
    ];

    for (final entry in masterIds) {
      await db.execute(
        'UPDATE clubs SET master_id = ? WHERE name = ? AND is_custom = 0',
        [entry[1], entry[0]],
      );
    }
  }

  // 新規インストール時のデフォルトクラブ一覧（完全版）
  Future<void> _insertDefaultClubs(Database db) async {
    final now = DateTime.now().toIso8601String();

    final defaultClubs = [
      // ウッド
      {'name': 'ドライバー',                    'category': 'ウッド',         'sort_order': 1,  'is_active': 1, 'master_id': 'driver'},
      {'name': '3番ウッド',                     'category': 'ウッド',         'sort_order': 2,  'is_active': 1, 'master_id': 'wood_3'},
      {'name': '5番ウッド',                     'category': 'ウッド',         'sort_order': 3,  'is_active': 1, 'master_id': 'wood_5'},
      {'name': '7番ウッド',                     'category': 'ウッド',         'sort_order': 4,  'is_active': 0, 'master_id': 'wood_7'},
      {'name': '9番ウッド',                     'category': 'ウッド',         'sort_order': 5,  'is_active': 0, 'master_id': 'wood_9'},
      {'name': '11番ウッド',                    'category': 'ウッド',         'sort_order': 6,  'is_active': 0, 'master_id': 'wood_11'},
      // ユーティリティ
      {'name': '2番ユーティリティ',             'category': 'ユーティリティ', 'sort_order': 7,  'is_active': 0, 'master_id': 'ut_2'},
      {'name': '3番ユーティリティ',             'category': 'ユーティリティ', 'sort_order': 8,  'is_active': 1, 'master_id': 'ut_3'},
      {'name': '4番ユーティリティ',             'category': 'ユーティリティ', 'sort_order': 9,  'is_active': 1, 'master_id': 'ut_4'},
      {'name': '5番ユーティリティ',             'category': 'ユーティリティ', 'sort_order': 10, 'is_active': 1, 'master_id': 'ut_5'},
      {'name': '6番ユーティリティ',             'category': 'ユーティリティ', 'sort_order': 11, 'is_active': 1, 'master_id': 'ut_6'},
      // アイアン
      {'name': '1番アイアン',                   'category': 'アイアン',       'sort_order': 12, 'is_active': 0, 'master_id': 'iron_1'},
      {'name': '2番アイアン',                   'category': 'アイアン',       'sort_order': 13, 'is_active': 0, 'master_id': 'iron_2'},
      {'name': '3番アイアン',                   'category': 'アイアン',       'sort_order': 14, 'is_active': 0, 'master_id': 'iron_3'},
      {'name': '4番アイアン',                   'category': 'アイアン',       'sort_order': 15, 'is_active': 0, 'master_id': 'iron_4'},
      {'name': '5番アイアン',                   'category': 'アイアン',       'sort_order': 16, 'is_active': 0, 'master_id': 'iron_5'},
      {'name': '6番アイアン',                   'category': 'アイアン',       'sort_order': 17, 'is_active': 1, 'master_id': 'iron_6'},
      {'name': '7番アイアン',                   'category': 'アイアン',       'sort_order': 18, 'is_active': 1, 'master_id': 'iron_7'},
      {'name': '8番アイアン',                   'category': 'アイアン',       'sort_order': 19, 'is_active': 1, 'master_id': 'iron_8'},
      {'name': '9番アイアン',                   'category': 'アイアン',       'sort_order': 20, 'is_active': 1, 'master_id': 'iron_9'},
      // ウェッジ
      {'name': 'ピッチングウェッジ（44〜47°）', 'category': 'ウェッジ',       'sort_order': 21, 'is_active': 1, 'master_id': 'wedge_pw'},
      {'name': 'アプローチウェッジ（48〜53°）', 'category': 'ウェッジ',       'sort_order': 22, 'is_active': 1, 'master_id': 'wedge_aw'},
      {'name': 'サンドウェッジ（54〜58°）',     'category': 'ウェッジ',       'sort_order': 23, 'is_active': 0, 'master_id': 'wedge_sw'},
      {'name': 'ロブウェッジ（58〜64°）',       'category': 'ウェッジ',       'sort_order': 24, 'is_active': 0, 'master_id': 'wedge_lw'},
      // その他
      {'name': 'パター',                        'category': 'その他',         'sort_order': 25, 'is_active': 0, 'master_id': 'putter'},
    ];

    for (final club in defaultClubs) {
      await db.insert('clubs', {
        ...club,
        'is_custom': 0,
        'created_at': now,
      });
    }
  }
}
