import 'package:flutter_test/flutter_test.dart';
import 'package:golf_memo/data/models/practice_memo.dart';

void main() {
  group('PracticeMemo モデル', () {
    // テスト用の基準日時
    final baseDate = DateTime(2025, 6, 15, 10, 30);
    final baseCreatedAt = DateTime(2025, 6, 15, 10, 30, 0);

    // 全フィールドが揃った Map
    final fullMap = {
      'practice_memo_id': 1,
      'club_id': 3,
      'practiced_at': '2025-06-15T10:30:00.000',
      'body': 'スイングが安定してきた',
      'condition': 'good',
      'distance': 230,
      'shot_shape': 'straight',
      'wind': 'normal',
      'is_favorite': 1,
      'created_at': '2025-06-15T10:30:00.000',
    };

    // 必須フィールドのみの Map（null許容フィールドは省略）
    final minimalMap = {
      'practice_memo_id': null,
      'club_id': 5,
      'practiced_at': '2025-06-01T08:00:00.000',
      'body': null,
      'condition': null,
      'distance': null,
      'shot_shape': null,
      'wind': null,
      'is_favorite': 0,
      'created_at': '2025-06-01T08:00:00.000',
    };

    // ──────────────────────────────────────────
    // fromMap のテスト
    // ──────────────────────────────────────────
    group('fromMap', () {
      test('全フィールドを正しくパースできる（正常系）', () {
        final memo = PracticeMemo.fromMap(fullMap);

        expect(memo.id, 1);
        expect(memo.clubId, 3);
        expect(memo.practicedAt, DateTime.parse('2025-06-15T10:30:00.000'));
        expect(memo.body, 'スイングが安定してきた');
        expect(memo.condition, 'good');
        expect(memo.distance, 230);
        expect(memo.shotShape, 'straight');
        expect(memo.wind, 'normal');
        expect(memo.isFavorite, true);
        expect(memo.createdAt, DateTime.parse('2025-06-15T10:30:00.000'));
      });

      test('null許容フィールドがnullのときも正しくパースできる（正常系）', () {
        final memo = PracticeMemo.fromMap(minimalMap);

        expect(memo.id, isNull);
        expect(memo.clubId, 5);
        expect(memo.body, isNull);
        expect(memo.condition, isNull);
        expect(memo.distance, isNull);
        expect(memo.shotShape, isNull);
        expect(memo.wind, isNull);
        expect(memo.isFavorite, false);
      });

      test('is_favorite = 0 のとき isFavorite が false になる', () {
        final map = {...fullMap, 'is_favorite': 0};
        final memo = PracticeMemo.fromMap(map);
        expect(memo.isFavorite, false);
      });

      test('practiced_at の日付文字列が正しく DateTime に変換される', () {
        final map = {...fullMap, 'practiced_at': '2024-01-01T00:00:00.000'};
        final memo = PracticeMemo.fromMap(map);
        expect(memo.practicedAt, DateTime(2024, 1, 1, 0, 0, 0));
      });

      test('club_id が存在しない場合は TypeError が発生する（異常系）', () {
        final badMap = Map<String, dynamic>.from(fullMap)..remove('club_id');
        expect(() => PracticeMemo.fromMap(badMap), throwsA(isA<TypeError>()));
      });

      test('practiced_at が不正な日付文字列の場合は FormatException が発生する（異常系）', () {
        final badMap = {...fullMap, 'practiced_at': 'not-a-date'};
        expect(
          () => PracticeMemo.fromMap(badMap),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // ──────────────────────────────────────────
    // toMap のテスト
    // ──────────────────────────────────────────
    group('toMap', () {
      test('全フィールドを正しく Map に変換できる（正常系）', () {
        final memo = PracticeMemo(
          id: 1,
          clubId: 3,
          practicedAt: DateTime.parse('2025-06-15T10:30:00.000'),
          body: 'スイングが安定してきた',
          condition: 'good',
          distance: 230,
          shotShape: 'straight',
          wind: 'normal',
          isFavorite: true,
          createdAt: DateTime.parse('2025-06-15T10:30:00.000'),
        );

        final map = memo.toMap();

        expect(map['practice_memo_id'], 1);
        expect(map['club_id'], 3);
        expect(map['body'], 'スイングが安定してきた');
        expect(map['condition'], 'good');
        expect(map['distance'], 230);
        expect(map['shot_shape'], 'straight');
        expect(map['wind'], 'normal');
        expect(map['is_favorite'], 1); // bool → int
      });

      test('isFavorite=false のとき is_favorite が 0 になる', () {
        final memo = PracticeMemo(
          clubId: 1,
          practicedAt: baseDate,
          isFavorite: false,
          createdAt: baseCreatedAt,
        );
        expect(memo.toMap()['is_favorite'], 0);
      });

      test('id が null のとき practice_memo_id キーが Map に含まれない', () {
        final memo = PracticeMemo(
          clubId: 1,
          practicedAt: baseDate,
          createdAt: baseCreatedAt,
        );
        expect(memo.toMap().containsKey('practice_memo_id'), false);
      });

      test('id が null でないとき practice_memo_id キーが Map に含まれる', () {
        final memo = PracticeMemo(
          id: 42,
          clubId: 1,
          practicedAt: baseDate,
          createdAt: baseCreatedAt,
        );
        expect(memo.toMap()['practice_memo_id'], 42);
      });

      test('fromMap → toMap のラウンドトリップで値が保持される（正常系）', () {
        final original = PracticeMemo.fromMap(fullMap);
        final roundTripped = PracticeMemo.fromMap(original.toMap());

        expect(roundTripped.id, original.id);
        expect(roundTripped.clubId, original.clubId);
        expect(roundTripped.practicedAt, original.practicedAt);
        expect(roundTripped.body, original.body);
        expect(roundTripped.condition, original.condition);
        expect(roundTripped.distance, original.distance);
        expect(roundTripped.shotShape, original.shotShape);
        expect(roundTripped.wind, original.wind);
        expect(roundTripped.isFavorite, original.isFavorite);
        expect(roundTripped.createdAt, original.createdAt);
      });
    });

    // ──────────────────────────────────────────
    // copyWith のテスト
    // ──────────────────────────────────────────
    group('copyWith', () {
      final original = PracticeMemo(
        id: 1,
        clubId: 3,
        practicedAt: baseDate,
        body: '元のメモ',
        condition: 'normal',
        distance: 200,
        shotShape: 'draw',
        wind: 'weak',
        isFavorite: false,
        createdAt: baseCreatedAt,
      );

      test('何も指定しない場合、元のオブジェクトと同じ値を持つ（正常系）', () {
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.clubId, original.clubId);
        expect(copied.practicedAt, original.practicedAt);
        expect(copied.body, original.body);
        expect(copied.condition, original.condition);
        expect(copied.distance, original.distance);
        expect(copied.shotShape, original.shotShape);
        expect(copied.wind, original.wind);
        expect(copied.isFavorite, original.isFavorite);
        expect(copied.createdAt, original.createdAt);
      });

      test('指定したフィールドだけ上書きされる（正常系）', () {
        final copied = original.copyWith(
          body: '新しいメモ',
          isFavorite: true,
          distance: 250,
        );

        expect(copied.body, '新しいメモ');
        expect(copied.isFavorite, true);
        expect(copied.distance, 250);
        // 変更していないフィールドは元のまま
        expect(copied.id, original.id);
        expect(copied.clubId, original.clubId);
        expect(copied.condition, original.condition);
        expect(copied.shotShape, original.shotShape);
      });

      test('id を上書きできる', () {
        final copied = original.copyWith(id: 99);
        expect(copied.id, 99);
      });

      test('clubId を上書きできる', () {
        final copied = original.copyWith(clubId: 10);
        expect(copied.clubId, 10);
      });
    });
  });
}
