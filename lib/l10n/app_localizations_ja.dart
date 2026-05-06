// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tabAll => 'すべて';

  @override
  String get tabFavorites => 'お気に入り';

  @override
  String get actionSave => '保存';

  @override
  String get actionEdit => '編集';

  @override
  String get actionDelete => '削除';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionDone => '完了';

  @override
  String get actionApply => '適用';

  @override
  String get actionClear => 'クリア';

  @override
  String get actionOk => 'OK';

  @override
  String get actionNext => '次へ';

  @override
  String get confirmDeleteTitle => '削除しますか？';

  @override
  String get confirmDeleteDescription => 'この記録を削除すると元に戻せません。';

  @override
  String get errorSaveFailed => '保存に失敗しました';

  @override
  String get errorRetryHint => 'もう一度お試しください。';

  @override
  String get dateToday => '今日';

  @override
  String get dateYesterday => '昨日';

  @override
  String dateDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get weekdayMon => '月';

  @override
  String get weekdayTue => '火';

  @override
  String get weekdayWed => '水';

  @override
  String get weekdayThu => '木';

  @override
  String get weekdayFri => '金';

  @override
  String get weekdaySat => '土';

  @override
  String get weekdaySun => '日';

  @override
  String dateFull(int month, int day, String weekday) {
    return '$month月$day日 $weekday曜日';
  }

  @override
  String dateFullWithYear(int year, int month, int day, String weekday) {
    return '$year年$month月$day日 $weekday曜日';
  }

  @override
  String get emptyNoRecords => 'まだ記録がありません。';

  @override
  String get emptyAddHint => '＋ボタンから追加しましょう！';

  @override
  String get emptyNoFavorites => 'お気に入りはまだありません';

  @override
  String get unknownClub => '不明なクラブ';

  @override
  String get labelClubSelect => 'クラブを選択';

  @override
  String get labelDistance => '飛距離';

  @override
  String get sectionShotShape => '球筋';

  @override
  String get sectionCondition => '調子';

  @override
  String get sectionWind => '風';

  @override
  String get placeholderBody => '練習内容・気づき';

  @override
  String get mediaLibrary => 'ライブラリから選ぶ';

  @override
  String get mediaCamera => '写真を撮る';

  @override
  String get mediaLimitHint => '※動画は1枚、画像は3枚まで追加できます。';

  @override
  String get actionOpenClubSettings => 'クラブの設定を開く';

  @override
  String get placeholderSearch => 'キーワード検索';

  @override
  String get filterClub => 'クラブ';

  @override
  String get filterDate => '日付';

  @override
  String get filterDistance => '飛距離';

  @override
  String get filterCondition => '調子';

  @override
  String get filterShotShape => '球筋';

  @override
  String get filterFavorite => 'お気に入り';

  @override
  String get filterAttachment => '添付ファイル';

  @override
  String get dateRange1m => '1ヶ月以前';

  @override
  String get dateRange6m => '6ヶ月以前';

  @override
  String get dateRange1y => '1年以前';

  @override
  String get filterNone => '指定なし';

  @override
  String get emptySearch => '記録が見つかりませんでした';

  @override
  String get tab30Days => '30日';

  @override
  String get tab60Days => '60日';

  @override
  String get sectionAvgDistance => 'クラブ別平均飛距離';

  @override
  String get sectionDistanceTrend => '飛距離の推移';

  @override
  String get emptyNoData => 'データがありません';

  @override
  String get emptyClubOff => '設定からクラブをONにしてください';

  @override
  String get onboardingTitle => '練習で使用するクラブを\n教えてください。';

  @override
  String get onboardingSubtitle1 => 'クラブごとにコツや飛距離を記録できます。';

  @override
  String get onboardingSubtitle2 => '設定はいつでも変えられます。';

  @override
  String get actionAddCustom => 'カスタムクラブを追加';

  @override
  String get navHome => 'ホーム';

  @override
  String get navSearch => '検索';

  @override
  String get navSummary => 'サマリー';

  @override
  String get navSettings => '設定';

  @override
  String get titleSettings => '設定';

  @override
  String get settingsClubs => '記録するクラブ';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsContact => 'お問い合わせ';

  @override
  String get settingsTerms => '規約・ライセンス';

  @override
  String get titleClubSettings => '記録するクラブ';

  @override
  String get titleCustomClub => 'カスタムクラブ';

  @override
  String get labelClubCategory => 'クラブのカテゴリ';

  @override
  String get placeholderClubName => 'クラブ名を入力';

  @override
  String get placeholderCategory => 'カテゴリ選択';

  @override
  String get actionDeleteClub => 'このクラブを削除する';

  @override
  String get confirmDeleteCustomClub => 'このカスタムクラブを削除します。';

  @override
  String get titleTerms => '規約・ライセンス';

  @override
  String get sectionTermsOfUse => '利用規約';

  @override
  String get sectionPrivacy => 'プライバシーポリシー';

  @override
  String get sectionLicense => 'ライセンス';

  @override
  String get placeholderPreparing => '準備中です。';

  @override
  String get tabLibrary => 'ライブラリ';

  @override
  String actionDoneCount(int count) {
    return '完了($count)';
  }

  @override
  String get emptyMedia => '写真・動画がありません';

  @override
  String get titleImagePreview => '画像プレビュー';

  @override
  String get titleVideoPreview => '動画プレビュー';

  @override
  String get actionSelectImage => 'この画像を選択する';

  @override
  String get actionSelectVideo => 'この動画を選択する';

  @override
  String get actionDeselect => '選択を解除する';

  @override
  String get errorMaxImages => '選択できる枚数の上限に達しました';
}
