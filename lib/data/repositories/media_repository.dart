import '../database/database_helper.dart';
import '../models/media.dart';

class MediaRepository {
  final _db = DatabaseHelper.instance;

  // メモに紐づくメディアを全件取得
  Future<List<Media>> getMediaByMemoId(int memoId) async {
    final db = await _db.database;
    final maps = await db.query(
      'media',
      where: 'practice_memo_id = ?',
      whereArgs: [memoId],
      orderBy: 'created_at ASC',
    );
    return maps.map(Media.fromMap).toList();
  }

  // メモに紐づく画像のみ取得
  Future<List<Media>> getImagesByMemoId(int memoId) async {
    final db = await _db.database;
    final maps = await db.query(
      'media',
      where: 'practice_memo_id = ? AND type = ?',
      whereArgs: [memoId, 'image'],
      orderBy: 'created_at ASC',
    );
    return maps.map(Media.fromMap).toList();
  }

  // メモに紐づく動画を取得
  Future<Media?> getVideoByMemoId(int memoId) async {
    final db = await _db.database;
    final maps = await db.query(
      'media',
      where: 'practice_memo_id = ? AND type = ?',
      whereArgs: [memoId, 'video'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Media.fromMap(maps.first);
  }

  // メディアを保存
  Future<Media> insertMedia(Media media) async {
    final db = await _db.database;
    final id = await db.insert('media', media.toMap());
    return Media(
      id: id,
      practiceMemoId: media.practiceMemoId,
      type: media.type,
      uri: media.uri,
      thumbnailUri: media.thumbnailUri,
      createdAt: media.createdAt,
    );
  }

  // メディアを削除
  Future<void> deleteMedia(int id) async {
    final db = await _db.database;
    await db.delete(
      'media',
      where: 'media_id = ?',
      whereArgs: [id],
    );
  }

  // メモに紐づくメディアを全件削除（メモ削除時に使用）
  Future<void> deleteMediaByMemoId(int memoId) async {
    final db = await _db.database;
    await db.delete(
      'media',
      where: 'practice_memo_id = ?',
      whereArgs: [memoId],
    );
  }
}
