import '../database/database_helper.dart';
import '../models/practice_memo.dart';

class PracticeMemoRepository {
  final _db = DatabaseHelper.instance;

  // 練習記録一覧を取得（新しい順）
  Future<List<PracticeMemo>> getAllMemos() async {
    final db = await _db.database;
    final maps = await db.query(
      'practice_memos',
      orderBy: 'practiced_at DESC',
    );
    return maps.map(PracticeMemo.fromMap).toList();
  }

  // お気に入り一覧を取得
  Future<List<PracticeMemo>> getFavoriteMemos() async {
    final db = await _db.database;
    final maps = await db.query(
      'practice_memos',
      where: 'is_favorite = 1',
      orderBy: 'practiced_at DESC',
    );
    return maps.map(PracticeMemo.fromMap).toList();
  }

  // 練習記録を1件取得
  Future<PracticeMemo?> getMemoById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'practice_memos',
      where: 'practice_memo_id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PracticeMemo.fromMap(maps.first);
  }

  // 検索・フィルター
  Future<List<PracticeMemo>> searchMemos({
    int? clubId,
    String? condition,
    List<String>? shotShapes,
    String? keyword,
    bool? isFavorite,
    DateTime? practicedBefore,
    int? distanceMin,
    int? distanceMax,
    bool? hasAttachment,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (clubId != null) {
      conditions.add('club_id = ?');
      args.add(clubId);
    }
    if (condition != null) {
      conditions.add('condition = ?');
      args.add(condition);
    }
    if (shotShapes != null && shotShapes.isNotEmpty) {
      final placeholders = shotShapes.map((_) => '?').join(',');
      conditions.add('shot_shape IN ($placeholders)');
      args.addAll(shotShapes);
    }
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add('body LIKE ?');
      args.add('%$keyword%');
    }
    if (isFavorite == true) {
      conditions.add('is_favorite = 1');
    }
    if (practicedBefore != null) {
      conditions.add('practiced_at <= ?');
      args.add(practicedBefore.toIso8601String());
    }
    if (distanceMin != null) {
      conditions.add('distance >= ?');
      args.add(distanceMin);
    }
    if (distanceMax != null) {
      conditions.add('distance <= ?');
      args.add(distanceMax);
    }
    if (hasAttachment == true) {
      conditions.add(
        'practice_memo_id IN (SELECT practice_memo_id FROM media)',
      );
    }

    final maps = await db.query(
      'practice_memos',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'practiced_at DESC',
    );
    return maps.map(PracticeMemo.fromMap).toList();
  }

  // 練習記録を保存
  Future<PracticeMemo> insertMemo(PracticeMemo memo) async {
    final db = await _db.database;
    final id = await db.insert('practice_memos', memo.toMap());
    return memo.copyWith(id: id);
  }

  // 練習記録を更新
  Future<void> updateMemo(PracticeMemo memo) async {
    final db = await _db.database;
    await db.update(
      'practice_memos',
      memo.toMap(),
      where: 'practice_memo_id = ?',
      whereArgs: [memo.id],
    );
  }

  // お気に入りの切り替え
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db.database;
    await db.update(
      'practice_memos',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'practice_memo_id = ?',
      whereArgs: [id],
    );
  }

  // 練習記録を削除
  Future<void> deleteMemo(int id) async {
    final db = await _db.database;
    await db.delete(
      'practice_memos',
      where: 'practice_memo_id = ?',
      whereArgs: [id],
    );
  }

  // レポート用：期間内の記録を取得
  Future<List<PracticeMemo>> getMemosByDateRange({
    required DateTime from,
    required DateTime to,
    int? clubId,
  }) async {
    final db = await _db.database;
    final conditions = [
      'practiced_at >= ?',
      'practiced_at <= ?',
    ];
    final args = <dynamic>[
      from.toIso8601String(),
      to.toIso8601String(),
    ];

    if (clubId != null) {
      conditions.add('club_id = ?');
      args.add(clubId);
    }

    final maps = await db.query(
      'practice_memos',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'practiced_at ASC',
    );
    return maps.map(PracticeMemo.fromMap).toList();
  }
}
