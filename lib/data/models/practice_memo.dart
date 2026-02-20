class PracticeMemo {
  final int? id;
  final int clubId;
  final DateTime practicedAt; // 練習した日
  final String? body;         // テキストメモ
  final String? condition;    // 調子: good / normal / bad
  final int? distance;        // 飛距離
  final String? shotShape;    // 球筋: straight / draw / fade / slice / hook
  final String? wind;         // 風: strong / normal / weak / none
  final bool isFavorite;
  final DateTime createdAt;

  const PracticeMemo({
    this.id,
    required this.clubId,
    required this.practicedAt,
    this.body,
    this.condition,
    this.distance,
    this.shotShape,
    this.wind,
    this.isFavorite = false,
    required this.createdAt,
  });

  // データベースから読み込むとき
  factory PracticeMemo.fromMap(Map<String, dynamic> map) {
    return PracticeMemo(
      id: map['practice_memo_id'] as int?,
      clubId: map['club_id'] as int,
      practicedAt: DateTime.parse(map['practiced_at'] as String),
      body: map['body'] as String?,
      condition: map['condition'] as String?,
      distance: map['distance'] as int?,
      shotShape: map['shot_shape'] as String?,
      wind: map['wind'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // データベースに保存するとき
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'practice_memo_id': id,
      'club_id': clubId,
      'practiced_at': practicedAt.toIso8601String(),
      'body': body,
      'condition': condition,
      'distance': distance,
      'shot_shape': shotShape,
      'wind': wind,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PracticeMemo copyWith({
    int? id,
    int? clubId,
    DateTime? practicedAt,
    String? body,
    String? condition,
    int? distance,
    String? shotShape,
    String? wind,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return PracticeMemo(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      practicedAt: practicedAt ?? this.practicedAt,
      body: body ?? this.body,
      condition: condition ?? this.condition,
      distance: distance ?? this.distance,
      shotShape: shotShape ?? this.shotShape,
      wind: wind ?? this.wind,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
