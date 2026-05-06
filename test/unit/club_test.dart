import 'package:flutter_test/flutter_test.dart';
import 'package:golf_memo/data/models/club.dart';

void main() {
  group('Club モデル', () {
    final baseCreatedAt = DateTime(2025, 1, 1, 9, 0);
    final baseDeletedAt = DateTime(2025, 3, 15, 12, 0);

    // 全フィールドが揃った Map
    final fullMap = {
      'club_id': 7,
      'name': '7番アイアン',
      'category': 'アイアン',
      'sort_order': 18,
      'is_active': 1,
      'is_custom': 0,
      'master_id': 'iron_7',
      'created_at': '2025-01-01T09:00:00.000',
      'deleted_at': null,
    };

    // カスタムクラブ・削除済みの Map
    final customDeletedMap = {
      'club_id': 100,
      'name': 'マイドライバー',
      'category': 'ウッド',
      'sort_order': 99,
      'is_active': 0,
      'is_custom': 1,
      'master_id': null,
      'created_at': '2025-01-01T09:00:00.000',
      'deleted_at': '2025-03-15T12:00:00.000',
    };

    // ──────────────────────────────────────────
    // fromMap のテスト
    // ──────────────────────────────────────────
    group('fromMap', () {
      test('全フィールドを正しくパースできる（正常系）', () {
        final club = Club.fromMap(fullMap);

        expect(club.id, 7);
        expect(club.name, '7番アイアン');
        expect(club.category, 'アイアン');
        expect(club.sortOrder, 18);
        expect(club.isActive, true);
        expect(club.isCustom, false);
        expect(club.masterId, 'iron_7');
        expect(club.createdAt, DateTime.parse('2025-01-01T09:00:00.000'));
        expect(club.deletedAt, isNull);
      });

      test('カスタムクラブ・削除済みの Map を正しくパースできる（正常系）', () {
        final club = Club.fromMap(customDeletedMap);

        expect(club.id, 100);
        expect(club.name, 'マイドライバー');
        expect(club.isCustom, true);
        expect(club.isActive, false);
        expect(club.masterId, isNull);
        expect(club.deletedAt, DateTime.parse('2025-03-15T12:00:00.000'));
      });

      test('is_active = 0 のとき isActive が false になる', () {
        final map = {...fullMap, 'is_active': 0};
        final club = Club.fromMap(map);
        expect(club.isActive, false);
      });

      test('is_custom = 1 のとき isCustom が true になる', () {
        final map = {...fullMap, 'is_custom': 1};
        final club = Club.fromMap(map);
        expect(club.isCustom, true);
      });

      test('name が存在しない場合は TypeError が発生する（異常系）', () {
        final badMap = Map<String, dynamic>.from(fullMap)..remove('name');
        expect(() => Club.fromMap(badMap), throwsA(isA<TypeError>()));
      });

      test('created_at が不正な日付文字列の場合は FormatException が発生する（異常系）', () {
        final badMap = {...fullMap, 'created_at': 'invalid-date'};
        expect(
          () => Club.fromMap(badMap),
          throwsA(isA<FormatException>()),
        );
      });

      test('deleted_at が不正な日付文字列の場合は FormatException が発生する（異常系）', () {
        final badMap = {...fullMap, 'deleted_at': 'bad-date'};
        expect(
          () => Club.fromMap(badMap),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // ──────────────────────────────────────────
    // toMap のテスト
    // ──────────────────────────────────────────
    group('toMap', () {
      test('全フィールドを正しく Map に変換できる（正常系）', () {
        final club = Club(
          id: 7,
          name: '7番アイアン',
          category: 'アイアン',
          sortOrder: 18,
          isActive: true,
          isCustom: false,
          masterId: 'iron_7',
          createdAt: DateTime.parse('2025-01-01T09:00:00.000'),
        );

        final map = club.toMap();

        expect(map['club_id'], 7);
        expect(map['name'], '7番アイアン');
        expect(map['category'], 'アイアン');
        expect(map['sort_order'], 18);
        expect(map['is_active'], 1);   // bool → int
        expect(map['is_custom'], 0);   // bool → int
        expect(map['master_id'], 'iron_7');
        expect(map['deleted_at'], isNull);
      });

      test('isActive=false のとき is_active が 0 になる', () {
        final club = Club(
          name: 'テスト',
          category: 'ウッド',
          sortOrder: 1,
          isActive: false,
          createdAt: baseCreatedAt,
        );
        expect(club.toMap()['is_active'], 0);
      });

      test('isCustom=true のとき is_custom が 1 になる', () {
        final club = Club(
          name: 'テスト',
          category: 'ウッド',
          sortOrder: 1,
          isCustom: true,
          createdAt: baseCreatedAt,
        );
        expect(club.toMap()['is_custom'], 1);
      });

      test('id が null のとき club_id キーが Map に含まれない', () {
        final club = Club(
          name: 'テスト',
          category: 'ウッド',
          sortOrder: 1,
          createdAt: baseCreatedAt,
        );
        expect(club.toMap().containsKey('club_id'), false);
      });

      test('id が非null のとき club_id キーが Map に含まれる', () {
        final club = Club(
          id: 5,
          name: 'テスト',
          category: 'ウッド',
          sortOrder: 1,
          createdAt: baseCreatedAt,
        );
        expect(club.toMap()['club_id'], 5);
      });

      test('deletedAt が設定されているとき deleted_at に ISO 文字列が入る', () {
        final club = Club(
          name: 'テスト',
          category: 'ウッド',
          sortOrder: 1,
          createdAt: baseCreatedAt,
          deletedAt: baseDeletedAt,
        );
        expect(club.toMap()['deleted_at'], baseDeletedAt.toIso8601String());
      });

      test('fromMap → toMap のラウンドトリップで値が保持される（正常系）', () {
        final original = Club.fromMap(customDeletedMap);
        final roundTripped = Club.fromMap(original.toMap());

        expect(roundTripped.id, original.id);
        expect(roundTripped.name, original.name);
        expect(roundTripped.category, original.category);
        expect(roundTripped.sortOrder, original.sortOrder);
        expect(roundTripped.isActive, original.isActive);
        expect(roundTripped.isCustom, original.isCustom);
        expect(roundTripped.masterId, original.masterId);
        expect(roundTripped.createdAt, original.createdAt);
        expect(roundTripped.deletedAt, original.deletedAt);
      });
    });

    // ──────────────────────────────────────────
    // copyWith のテスト
    // ──────────────────────────────────────────
    group('copyWith', () {
      final original = Club(
        id: 7,
        name: '7番アイアン',
        category: 'アイアン',
        sortOrder: 18,
        isActive: true,
        isCustom: false,
        masterId: 'iron_7',
        createdAt: baseCreatedAt,
      );

      test('何も指定しない場合、元のオブジェクトと同じ値を持つ（正常系）', () {
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.category, original.category);
        expect(copied.sortOrder, original.sortOrder);
        expect(copied.isActive, original.isActive);
        expect(copied.isCustom, original.isCustom);
        expect(copied.masterId, original.masterId);
        expect(copied.createdAt, original.createdAt);
        expect(copied.deletedAt, original.deletedAt);
      });

      test('指定したフィールドだけ上書きされる（正常系）', () {
        final copied = original.copyWith(
          name: 'マイ7番アイアン',
          isActive: false,
          isCustom: true,
        );

        expect(copied.name, 'マイ7番アイアン');
        expect(copied.isActive, false);
        expect(copied.isCustom, true);
        // 変更していないフィールドは元のまま
        expect(copied.id, original.id);
        expect(copied.category, original.category);
        expect(copied.sortOrder, original.sortOrder);
        expect(copied.masterId, original.masterId);
      });

      test('sortOrder を上書きできる', () {
        final copied = original.copyWith(sortOrder: 99);
        expect(copied.sortOrder, 99);
      });

      test('deletedAt を設定できる', () {
        final copied = original.copyWith(deletedAt: baseDeletedAt);
        expect(copied.deletedAt, baseDeletedAt);
      });
    });
  });
}
