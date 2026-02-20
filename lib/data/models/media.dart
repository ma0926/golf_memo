class Media {
  final int? id;
  final int practiceMemoId;
  final String type;         // image / video
  final String uri;          // ファイルの保存先パス
  final String? thumbnailUri; // サムネイルの保存先パス（動画用）
  final DateTime createdAt;

  const Media({
    this.id,
    required this.practiceMemoId,
    required this.type,
    required this.uri,
    this.thumbnailUri,
    required this.createdAt,
  });

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  // データベースから読み込むとき
  factory Media.fromMap(Map<String, dynamic> map) {
    return Media(
      id: map['media_id'] as int?,
      practiceMemoId: map['practice_memo_id'] as int,
      type: map['type'] as String,
      uri: map['uri'] as String,
      thumbnailUri: map['thumbnail_uri'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // データベースに保存するとき
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'media_id': id,
      'practice_memo_id': practiceMemoId,
      'type': type,
      'uri': uri,
      'thumbnail_uri': thumbnailUri,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
