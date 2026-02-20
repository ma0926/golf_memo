import '../database/database_helper.dart';
import '../models/club.dart';

class ClubRepository {
  final _db = DatabaseHelper.instance;

  // 有効なクラブ一覧を取得（削除済みは除く）
  Future<List<Club>> getActiveClubs() async {
    final db = await _db.database;
    final maps = await db.query(
      'clubs',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC',
    );
    return maps.map(Club.fromMap).toList();
  }

  // ONになっているクラブのみ取得（記録作成画面用）
  Future<List<Club>> getActiveOnClubs() async {
    final db = await _db.database;
    final maps = await db.query(
      'clubs',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'sort_order ASC',
    );
    return maps.map(Club.fromMap).toList();
  }

  // クラブを1件取得
  Future<Club?> getClubById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'clubs',
      where: 'club_id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Club.fromMap(maps.first);
  }

  // クラブを追加（カスタムクラブ）
  Future<Club> insertClub(Club club) async {
    final db = await _db.database;
    final id = await db.insert('clubs', club.toMap());
    return club.copyWith(id: id);
  }

  // クラブを更新（名前・カテゴリ・ON/OFF・並び順）
  Future<void> updateClub(Club club) async {
    final db = await _db.database;
    await db.update(
      'clubs',
      club.toMap(),
      where: 'club_id = ?',
      whereArgs: [club.id],
    );
  }

  // カスタムクラブを削除（ソフトデリート）
  Future<void> deleteClub(int id) async {
    final db = await _db.database;
    await db.update(
      'clubs',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'club_id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }
}
