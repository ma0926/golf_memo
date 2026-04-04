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
    'yes',
    'none',
  ];

  // 調子の表示ラベル
  static const Map<String, String> conditionLabels = {
    'good':   '絶好調',
    'normal': 'いつもの調子',
    'bad':    'いまひとつ',
  };

  // 球筋の表示ラベル
  static const Map<String, String> shotShapeLabels = {
    'draw':     'ドロー',
    'straight': 'ストレート',
    'fade':     'フェード',
    'hook':     'フック',
    'slice':    'スライス',
  };

  // 風の表示ラベル
  static const Map<String, String> windLabels = {
    'yes':  'あり',
    'none': 'なし',
  };
}
