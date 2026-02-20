class Club {
  final int? id;
  final String name;
  final String category; // ウッド / ユーティリティ / アイアン / ウェッジ / その他
  final int sortOrder;
  final bool isActive;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime? deletedAt; // カスタムクラブの削除用（ソフトデリート）

  const Club({
    this.id,
    required this.name,
    required this.category,
    required this.sortOrder,
    this.isActive = true,
    this.isCustom = false,
    required this.createdAt,
    this.deletedAt,
  });

  // データベースから読み込むとき
  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['club_id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      sortOrder: map['sort_order'] as int,
      isActive: (map['is_active'] as int) == 1,
      isCustom: (map['is_custom'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  // データベースに保存するとき
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'club_id': id,
      'name': name,
      'category': category,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Club copyWith({
    int? id,
    String? name,
    String? category,
    int? sortOrder,
    bool? isActive,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
