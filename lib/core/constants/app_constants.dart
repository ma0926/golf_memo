// アプリ全体で使う定数
class AppConstants {
  AppConstants._();

  // Phase 1（無料版）のメディア制限
  static const int maxImagesPerMemo = 3;    // 画像は最大3枚
  static const int maxVideosPerMemo = 1;    // 動画は最大1本
  static const int maxVideoSeconds = 10;    // 動画は最大10秒

  // クラブのカテゴリ
  static const List<String> clubCategories = [
    'ウッド',
    'ユーティリティ',
    'アイアン',
    'ウェッジ',
    'その他',
  ];

  // 調子の選択肢
  static const List<String> conditions = ['good', 'normal', 'bad'];

  // 球筋の選択肢
  static const List<String> shotShapes = [
    'straight',
    'draw',
    'fade',
    'slice',
    'hook',
  ];

  // 風の選択肢
  static const List<String> windConditions = [
    'strong',
    'normal',
    'weak',
    'none',
  ];

  // 調子の表示ラベル
  static const Map<String, String> conditionLabels = {
    'good':   '良い',
    'normal': '普通',
    'bad':    '悪い',
  };

  // 球筋の表示ラベル
  static const Map<String, String> shotShapeLabels = {
    'straight': 'ストレート',
    'draw':     'ドロー',
    'fade':     'フェード',
    'slice':    'スライス',
    'hook':     'フック',
  };

  // 風の表示ラベル
  static const Map<String, String> windLabels = {
    'strong': '強',
    'normal': '中',
    'weak':   '弱',
    'none':   'なし',
  };
}
