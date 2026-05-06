import 'package:flutter_test/flutter_test.dart';
import 'package:golf_memo/data/models/media.dart';

void main() {
  group('Media モデル', () {
    // ──────────────────────────────────────────
    // fromMap のテスト
    // ──────────────────────────────────────────
    group('fromMap', () {
      test('画像メディア（thumbnail_uri なし）を正しくパースできる（正常系）', () {
        final map = {
          'media_id': 1,
          'practice_memo_id': 10,
          'type': 'image',
          'uri': '/path/to/image.jpg',
          'thumbnail_uri': null,
          'created_at': '2025-06-01T12:00:00.000',
        };

        final media = Media.fromMap(map);

        expect(media.id, 1);
        expect(media.practiceMemoId, 10);
        expect(media.type, 'image');
        expect(media.uri, '/path/to/image.jpg');
        expect(media.thumbnailUri, isNull);
        expect(media.createdAt, DateTime.parse('2025-06-01T12:00:00.000'));
      });

      test('動画メディア（thumbnail_uri あり）を正しくパースできる（正常系）', () {
        final map = {
          'media_id': 2,
          'practice_memo_id': 10,
          'type': 'video',
          'uri': '/path/to/video.mp4',
          'thumbnail_uri': '/path/to/thumb.jpg',
          'created_at': '2025-06-01T12:00:00.000',
        };

        final media = Media.fromMap(map);

        expect(media.type, 'video');
        expect(media.uri, '/path/to/video.mp4');
        expect(media.thumbnailUri, '/path/to/thumb.jpg');
        expect(media.isVideo, true);
        expect(media.isImage, false);
      });

      test('id が null の場合も正しくパースできる（正常系）', () {
        final map = {
          'media_id': null,
          'practice_memo_id': 5,
          'type': 'image',
          'uri': '/path/to/image.png',
          'thumbnail_uri': null,
          'created_at': '2025-06-01T12:00:00.000',
        };

        final media = Media.fromMap(map);
        expect(media.id, isNull);
      });

      test('isImage ゲッターが image のときに true を返す', () {
        final map = {
          'media_id': 3,
          'practice_memo_id': 1,
          'type': 'image',
          'uri': '/path/image.jpg',
          'thumbnail_uri': null,
          'created_at': '2025-06-01T12:00:00.000',
        };
        final media = Media.fromMap(map);
        expect(media.isImage, true);
        expect(media.isVideo, false);
      });

      test('created_at が不正な日付文字列の場合は FormatException が発生する（異常系）', () {
        final badMap = {
          'media_id': 1,
          'practice_memo_id': 1,
          'type': 'image',
          'uri': '/path/image.jpg',
          'thumbnail_uri': null,
          'created_at': 'not-a-date',
        };
        expect(
          () => Media.fromMap(badMap),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // ──────────────────────────────────────────
    // toMap のテスト
    // ──────────────────────────────────────────
    group('toMap', () {
      test('全フィールドを正しく Map に変換できる（正常系）', () {
        final createdAt = DateTime.parse('2025-06-01T12:00:00.000');
        final media = Media(
          id: 1,
          practiceMemoId: 10,
          type: 'video',
          uri: '/path/to/video.mp4',
          thumbnailUri: '/path/to/thumb.jpg',
          createdAt: createdAt,
        );

        final map = media.toMap();

        expect(map['media_id'], 1);
        expect(map['practice_memo_id'], 10);
        expect(map['type'], 'video');
        expect(map['uri'], '/path/to/video.mp4');
        expect(map['thumbnail_uri'], '/path/to/thumb.jpg');
        expect(map['created_at'], createdAt.toIso8601String());
      });

      test('id が null のとき media_id キーが Map に含まれない', () {
        final media = Media(
          practiceMemoId: 1,
          type: 'image',
          uri: '/path/image.jpg',
          createdAt: DateTime.now(),
        );
        expect(media.toMap().containsKey('media_id'), false);
      });

      test('id が非null のとき media_id キーが Map に含まれる', () {
        final media = Media(
          id: 99,
          practiceMemoId: 1,
          type: 'image',
          uri: '/path/image.jpg',
          createdAt: DateTime.now(),
        );
        expect(media.toMap()['media_id'], 99);
      });

      test('thumbnailUri が null のとき thumbnail_uri が null になる', () {
        final media = Media(
          practiceMemoId: 1,
          type: 'image',
          uri: '/path/image.jpg',
          createdAt: DateTime.now(),
        );
        expect(media.toMap()['thumbnail_uri'], isNull);
      });

      test('fromMap → toMap のラウンドトリップで値が保持される（正常系）', () {
        final originalMap = {
          'media_id': 5,
          'practice_memo_id': 20,
          'type': 'video',
          'uri': '/path/video.mp4',
          'thumbnail_uri': '/path/thumb.jpg',
          'created_at': '2025-06-01T12:00:00.000',
        };

        final media = Media.fromMap(originalMap);
        final roundTripped = Media.fromMap(media.toMap());

        expect(roundTripped.id, media.id);
        expect(roundTripped.practiceMemoId, media.practiceMemoId);
        expect(roundTripped.type, media.type);
        expect(roundTripped.uri, media.uri);
        expect(roundTripped.thumbnailUri, media.thumbnailUri);
        expect(roundTripped.createdAt, media.createdAt);
      });
    });
  });
}
