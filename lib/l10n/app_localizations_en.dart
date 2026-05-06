// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabAll => 'All';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get actionSave => 'Save';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionOk => 'OK';

  @override
  String get actionNext => 'Next';

  @override
  String get confirmDeleteTitle => 'Delete this record?';

  @override
  String get confirmDeleteDescription => 'This action cannot be undone.';

  @override
  String get errorSaveFailed => 'Failed to save';

  @override
  String get errorRetryHint => 'Please try again.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String dateFull(int month, int day, String weekday) {
    return '$weekday, $month/$day';
  }

  @override
  String dateFullWithYear(int year, int month, int day, String weekday) {
    return '$weekday, $month/$day/$year';
  }

  @override
  String get emptyNoRecords => 'No records yet.';

  @override
  String get emptyAddHint => 'Tap + to add your first record!';

  @override
  String get emptyNoFavorites => 'No favorites yet';

  @override
  String get unknownClub => 'Unknown club';

  @override
  String get labelClubSelect => 'Select Club';

  @override
  String get labelDistance => 'Distance';

  @override
  String get sectionShotShape => 'Shot Shape';

  @override
  String get sectionCondition => 'Condition';

  @override
  String get sectionWind => 'Wind';

  @override
  String get placeholderBody => 'Notes & observations';

  @override
  String get mediaLibrary => 'Choose from Library';

  @override
  String get mediaCamera => 'Take Photo';

  @override
  String get mediaLimitHint => 'Up to 1 video and 3 photos.';

  @override
  String get actionOpenClubSettings => 'Open Club Settings';

  @override
  String get placeholderSearch => 'Search';

  @override
  String get filterClub => 'Club';

  @override
  String get filterDate => 'Date';

  @override
  String get filterDistance => 'Distance';

  @override
  String get filterCondition => 'Condition';

  @override
  String get filterShotShape => 'Shot Shape';

  @override
  String get filterFavorite => 'Favorites';

  @override
  String get filterAttachment => 'Has Attachment';

  @override
  String get dateRange1m => 'Last month';

  @override
  String get dateRange6m => 'Last 6 months';

  @override
  String get dateRange1y => 'Last year';

  @override
  String get filterNone => 'Any';

  @override
  String get emptySearch => 'No records found';

  @override
  String get tab30Days => '30 Days';

  @override
  String get tab60Days => '60 Days';

  @override
  String get sectionAvgDistance => 'Average Distance by Club';

  @override
  String get sectionDistanceTrend => 'Distance Trend';

  @override
  String get emptyNoData => 'No data available';

  @override
  String get emptyClubOff => 'Enable clubs in Settings';

  @override
  String get onboardingTitle => 'Select your clubs.';

  @override
  String get onboardingSubtitle1 => 'Track tips and distances for each club.';

  @override
  String get onboardingSubtitle2 => 'You can change this anytime in Settings.';

  @override
  String get actionAddCustom => 'Add Custom Club';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSummary => 'Summary';

  @override
  String get navSettings => 'Settings';

  @override
  String get titleSettings => 'Settings';

  @override
  String get settingsClubs => 'Clubs';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsContact => 'Contact Us';

  @override
  String get settingsTerms => 'Terms & Licenses';

  @override
  String get titleClubSettings => 'Clubs';

  @override
  String get titleCustomClub => 'Custom Club';

  @override
  String get labelClubCategory => 'Category';

  @override
  String get placeholderClubName => 'Club name';

  @override
  String get placeholderCategory => 'Select category';

  @override
  String get actionDeleteClub => 'Delete this club';

  @override
  String get confirmDeleteCustomClub => 'This custom club will be deleted.';

  @override
  String get titleTerms => 'Terms & Licenses';

  @override
  String get sectionTermsOfUse => 'Terms of Use';

  @override
  String get sectionPrivacy => 'Privacy Policy';

  @override
  String get sectionLicense => 'Licenses';

  @override
  String get placeholderPreparing => 'Coming soon.';

  @override
  String get tabLibrary => 'Library';

  @override
  String actionDoneCount(int count) {
    return 'Done ($count)';
  }

  @override
  String get emptyMedia => 'No photos or videos';

  @override
  String get titleImagePreview => 'Image Preview';

  @override
  String get titleVideoPreview => 'Video Preview';

  @override
  String get actionSelectImage => 'Select this image';

  @override
  String get actionSelectVideo => 'Select this video';

  @override
  String get actionDeselect => 'Deselect';

  @override
  String get errorMaxImages => 'Maximum photos selected';
}
