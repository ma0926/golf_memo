import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @tabAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get tabAll;

  /// No description provided for @tabFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get tabFavorites;

  /// No description provided for @actionSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get actionSave;

  /// No description provided for @actionEdit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get actionDelete;

  /// No description provided for @actionCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get actionCancel;

  /// No description provided for @actionDone.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get actionDone;

  /// No description provided for @actionApply.
  ///
  /// In ja, this message translates to:
  /// **'適用'**
  String get actionApply;

  /// No description provided for @actionClear.
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get actionClear;

  /// No description provided for @actionOk.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionNext.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get actionNext;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除しますか？'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteDescription.
  ///
  /// In ja, this message translates to:
  /// **'この記録を削除すると元に戻せません。'**
  String get confirmDeleteDescription;

  /// No description provided for @errorSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました'**
  String get errorSaveFailed;

  /// No description provided for @errorRetryHint.
  ///
  /// In ja, this message translates to:
  /// **'もう一度お試しください。'**
  String get errorRetryHint;

  /// No description provided for @dateToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In ja, this message translates to:
  /// **'{count}日前'**
  String dateDaysAgo(int count);

  /// No description provided for @weekdayMon.
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ja, this message translates to:
  /// **'火'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ja, this message translates to:
  /// **'水'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ja, this message translates to:
  /// **'木'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ja, this message translates to:
  /// **'金'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ja, this message translates to:
  /// **'土'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @dateFull.
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日 {weekday}曜日'**
  String dateFull(int month, int day, String weekday);

  /// No description provided for @dateFullWithYear.
  ///
  /// In ja, this message translates to:
  /// **'{year}年{month}月{day}日 {weekday}曜日'**
  String dateFullWithYear(int year, int month, int day, String weekday);

  /// No description provided for @emptyNoRecords.
  ///
  /// In ja, this message translates to:
  /// **'まだ記録がありません。'**
  String get emptyNoRecords;

  /// No description provided for @emptyAddHint.
  ///
  /// In ja, this message translates to:
  /// **'＋ボタンから追加しましょう！'**
  String get emptyAddHint;

  /// No description provided for @emptyNoFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りはまだありません'**
  String get emptyNoFavorites;

  /// No description provided for @unknownClub.
  ///
  /// In ja, this message translates to:
  /// **'不明なクラブ'**
  String get unknownClub;

  /// No description provided for @labelClubSelect.
  ///
  /// In ja, this message translates to:
  /// **'クラブを選択'**
  String get labelClubSelect;

  /// No description provided for @labelDistance.
  ///
  /// In ja, this message translates to:
  /// **'飛距離'**
  String get labelDistance;

  /// No description provided for @sectionShotShape.
  ///
  /// In ja, this message translates to:
  /// **'球筋'**
  String get sectionShotShape;

  /// No description provided for @sectionCondition.
  ///
  /// In ja, this message translates to:
  /// **'調子'**
  String get sectionCondition;

  /// No description provided for @sectionWind.
  ///
  /// In ja, this message translates to:
  /// **'風'**
  String get sectionWind;

  /// No description provided for @placeholderBody.
  ///
  /// In ja, this message translates to:
  /// **'練習内容・気づき'**
  String get placeholderBody;

  /// No description provided for @mediaLibrary.
  ///
  /// In ja, this message translates to:
  /// **'ライブラリから選ぶ'**
  String get mediaLibrary;

  /// No description provided for @mediaCamera.
  ///
  /// In ja, this message translates to:
  /// **'写真を撮る'**
  String get mediaCamera;

  /// No description provided for @mediaLimitHint.
  ///
  /// In ja, this message translates to:
  /// **'※動画は1枚、画像は3枚まで追加できます。'**
  String get mediaLimitHint;

  /// No description provided for @actionOpenClubSettings.
  ///
  /// In ja, this message translates to:
  /// **'クラブの設定を開く'**
  String get actionOpenClubSettings;

  /// No description provided for @placeholderSearch.
  ///
  /// In ja, this message translates to:
  /// **'キーワード検索'**
  String get placeholderSearch;

  /// No description provided for @filterClub.
  ///
  /// In ja, this message translates to:
  /// **'クラブ'**
  String get filterClub;

  /// No description provided for @filterDate.
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get filterDate;

  /// No description provided for @filterDistance.
  ///
  /// In ja, this message translates to:
  /// **'飛距離'**
  String get filterDistance;

  /// No description provided for @filterCondition.
  ///
  /// In ja, this message translates to:
  /// **'調子'**
  String get filterCondition;

  /// No description provided for @filterShotShape.
  ///
  /// In ja, this message translates to:
  /// **'球筋'**
  String get filterShotShape;

  /// No description provided for @filterFavorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get filterFavorite;

  /// No description provided for @filterAttachment.
  ///
  /// In ja, this message translates to:
  /// **'添付ファイル'**
  String get filterAttachment;

  /// No description provided for @dateRange1m.
  ///
  /// In ja, this message translates to:
  /// **'1ヶ月以前'**
  String get dateRange1m;

  /// No description provided for @dateRange6m.
  ///
  /// In ja, this message translates to:
  /// **'6ヶ月以前'**
  String get dateRange6m;

  /// No description provided for @dateRange1y.
  ///
  /// In ja, this message translates to:
  /// **'1年以前'**
  String get dateRange1y;

  /// No description provided for @filterNone.
  ///
  /// In ja, this message translates to:
  /// **'指定なし'**
  String get filterNone;

  /// No description provided for @emptySearch.
  ///
  /// In ja, this message translates to:
  /// **'記録が見つかりませんでした'**
  String get emptySearch;

  /// No description provided for @tab30Days.
  ///
  /// In ja, this message translates to:
  /// **'30日'**
  String get tab30Days;

  /// No description provided for @tab60Days.
  ///
  /// In ja, this message translates to:
  /// **'60日'**
  String get tab60Days;

  /// No description provided for @sectionAvgDistance.
  ///
  /// In ja, this message translates to:
  /// **'クラブ別平均飛距離'**
  String get sectionAvgDistance;

  /// No description provided for @sectionDistanceTrend.
  ///
  /// In ja, this message translates to:
  /// **'飛距離の推移'**
  String get sectionDistanceTrend;

  /// No description provided for @emptyNoData.
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get emptyNoData;

  /// No description provided for @emptyClubOff.
  ///
  /// In ja, this message translates to:
  /// **'設定からクラブをONにしてください'**
  String get emptyClubOff;

  /// No description provided for @onboardingTitle.
  ///
  /// In ja, this message translates to:
  /// **'練習で使用するクラブを\n教えてください。'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In ja, this message translates to:
  /// **'クラブごとにコツや飛距離を記録できます。'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In ja, this message translates to:
  /// **'設定はいつでも変えられます。'**
  String get onboardingSubtitle2;

  /// No description provided for @actionAddCustom.
  ///
  /// In ja, this message translates to:
  /// **'カスタムクラブを追加'**
  String get actionAddCustom;

  /// No description provided for @navHome.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get navSearch;

  /// No description provided for @navSummary.
  ///
  /// In ja, this message translates to:
  /// **'サマリー'**
  String get navSummary;

  /// No description provided for @navSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get navSettings;

  /// No description provided for @titleSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get titleSettings;

  /// No description provided for @settingsClubs.
  ///
  /// In ja, this message translates to:
  /// **'記録するクラブ'**
  String get settingsClubs;

  /// No description provided for @settingsAbout.
  ///
  /// In ja, this message translates to:
  /// **'このアプリについて'**
  String get settingsAbout;

  /// No description provided for @settingsContact.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get settingsContact;

  /// No description provided for @settingsTerms.
  ///
  /// In ja, this message translates to:
  /// **'規約・ライセンス'**
  String get settingsTerms;

  /// No description provided for @titleClubSettings.
  ///
  /// In ja, this message translates to:
  /// **'記録するクラブ'**
  String get titleClubSettings;

  /// No description provided for @titleCustomClub.
  ///
  /// In ja, this message translates to:
  /// **'カスタムクラブ'**
  String get titleCustomClub;

  /// No description provided for @labelClubCategory.
  ///
  /// In ja, this message translates to:
  /// **'クラブのカテゴリ'**
  String get labelClubCategory;

  /// No description provided for @placeholderClubName.
  ///
  /// In ja, this message translates to:
  /// **'クラブ名を入力'**
  String get placeholderClubName;

  /// No description provided for @placeholderCategory.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ選択'**
  String get placeholderCategory;

  /// No description provided for @actionDeleteClub.
  ///
  /// In ja, this message translates to:
  /// **'このクラブを削除する'**
  String get actionDeleteClub;

  /// No description provided for @confirmDeleteCustomClub.
  ///
  /// In ja, this message translates to:
  /// **'このカスタムクラブを削除します。'**
  String get confirmDeleteCustomClub;

  /// No description provided for @titleTerms.
  ///
  /// In ja, this message translates to:
  /// **'規約・ライセンス'**
  String get titleTerms;

  /// No description provided for @sectionTermsOfUse.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get sectionTermsOfUse;

  /// No description provided for @sectionPrivacy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get sectionPrivacy;

  /// No description provided for @sectionLicense.
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get sectionLicense;

  /// No description provided for @placeholderPreparing.
  ///
  /// In ja, this message translates to:
  /// **'準備中です。'**
  String get placeholderPreparing;

  /// No description provided for @tabLibrary.
  ///
  /// In ja, this message translates to:
  /// **'ライブラリ'**
  String get tabLibrary;

  /// No description provided for @actionDoneCount.
  ///
  /// In ja, this message translates to:
  /// **'完了({count})'**
  String actionDoneCount(int count);

  /// No description provided for @emptyMedia.
  ///
  /// In ja, this message translates to:
  /// **'写真・動画がありません'**
  String get emptyMedia;

  /// No description provided for @titleImagePreview.
  ///
  /// In ja, this message translates to:
  /// **'画像プレビュー'**
  String get titleImagePreview;

  /// No description provided for @titleVideoPreview.
  ///
  /// In ja, this message translates to:
  /// **'動画プレビュー'**
  String get titleVideoPreview;

  /// No description provided for @actionSelectImage.
  ///
  /// In ja, this message translates to:
  /// **'この画像を選択する'**
  String get actionSelectImage;

  /// No description provided for @actionSelectVideo.
  ///
  /// In ja, this message translates to:
  /// **'この動画を選択する'**
  String get actionSelectVideo;

  /// No description provided for @actionDeselect.
  ///
  /// In ja, this message translates to:
  /// **'選択を解除する'**
  String get actionDeselect;

  /// No description provided for @errorMaxImages.
  ///
  /// In ja, this message translates to:
  /// **'選択できる枚数の上限に達しました'**
  String get errorMaxImages;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
