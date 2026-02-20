import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'golf_memo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // クラブテーブル
    await db.execute('''
      CREATE TABLE clubs (
        club_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        category    TEXT    NOT NULL,
        sort_order  INTEGER NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1,
        is_custom   INTEGER NOT NULL DEFAULT 0,
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

    // デフォルトクラブを初期データとして追加
    await _insertDefaultClubs(db);
  }

  // アプリ初回起動時に入れておくデフォルトクラブ一覧
  Future<void> _insertDefaultClubs(Database db) async {
    final now = DateTime.now().toIso8601String();

    final defaultClubs = [
      // ウッド
      {'name': 'ドライバー', 'category': 'ウッド',       'sort_order': 1},
      {'name': '3W',        'category': 'ウッド',       'sort_order': 2},
      {'name': '5W',        'category': 'ウッド',       'sort_order': 3},
      // ユーティリティ
      {'name': '3U',        'category': 'ユーティリティ', 'sort_order': 4},
      {'name': '4U',        'category': 'ユーティリティ', 'sort_order': 5},
      // アイアン
      {'name': '5I',        'category': 'アイアン',      'sort_order': 6},
      {'name': '6I',        'category': 'アイアン',      'sort_order': 7},
      {'name': '7I',        'category': 'アイアン',      'sort_order': 8},
      {'name': '8I',        'category': 'アイアン',      'sort_order': 9},
      {'name': '9I',        'category': 'アイアン',      'sort_order': 10},
      // ウェッジ
      {'name': 'PW',        'category': 'ウェッジ',      'sort_order': 11},
      {'name': 'AW',        'category': 'ウェッジ',      'sort_order': 12},
      {'name': 'SW',        'category': 'ウェッジ',      'sort_order': 13},
      // パター
      {'name': 'パター',    'category': 'その他',        'sort_order': 14},
    ];

    for (final club in defaultClubs) {
      await db.insert('clubs', {
        ...club,
        'is_active': 1,
        'is_custom': 0,
        'created_at': now,
      });
    }
  }
}
