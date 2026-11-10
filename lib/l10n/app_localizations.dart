import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('am'),
    Locale('en'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Kiko'**
  String get appTitle;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Generic save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Skip action (first-launch setup)
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Generic OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Generic done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Search action / screen title
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Leads list screen title
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leads;

  /// Recent calls screen title
  ///
  /// In en, this message translates to:
  /// **'Recent Calls'**
  String get recentCalls;

  /// Call plan screen title
  ///
  /// In en, this message translates to:
  /// **'Call Plan'**
  String get callPlan;

  /// Export action/screen title
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import action/screen title
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Import leads list tile title
  ///
  /// In en, this message translates to:
  /// **'Import Leads'**
  String get importLeads;

  /// Export leads list tile title
  ///
  /// In en, this message translates to:
  /// **'Export Leads'**
  String get exportLeads;

  /// Permissions section/screen title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Overlay settings section title
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get overlay;

  /// Calls settings section title
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get calls;

  /// Data settings section title
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// About settings section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Overlay master toggle title
  ///
  /// In en, this message translates to:
  /// **'Show caller overlay'**
  String get showCallerOverlay;

  /// Overlay master toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Display lead info during incoming calls'**
  String get showCallerOverlaySubtitle;

  /// Overlay history toggle title
  ///
  /// In en, this message translates to:
  /// **'Show call history'**
  String get showCallHistory;

  /// Overlay history toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Include last note and last call date in overlay'**
  String get showCallHistorySubtitle;

  /// Ask unknown toggle title
  ///
  /// In en, this message translates to:
  /// **'Ask about unknown callers'**
  String get askUnknownCallers;

  /// Ask unknown toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Show \"Is this a lead?\" dialog for unrecognised numbers'**
  String get askUnknownCallersSubtitle;

  /// Reset dismissed numbers list tile title
  ///
  /// In en, this message translates to:
  /// **'Reset dismissed numbers'**
  String get resetDismissedNumbers;

  /// Reset dismissed numbers subtitle
  ///
  /// In en, this message translates to:
  /// **'Start asking again about previously dismissed callers'**
  String get resetDismissedNumbersSubtitle;

  /// Confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset dismissed numbers?'**
  String get resetDismissedNumbersConfirmTitle;

  /// Confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Kiko will start asking again whether unknown callers you previously dismissed are leads.'**
  String get resetDismissedNumbersConfirmBody;

  /// Recent calls list tile title
  ///
  /// In en, this message translates to:
  /// **'Recent calls'**
  String get viewRecentCalls;

  /// Recent calls list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'View call log and add leads'**
  String get viewRecentCallsSubtitle;

  /// Permissions list tile title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get viewPermissions;

  /// Permissions list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Grant or review required permissions'**
  String get viewPermissionsSubtitle;

  /// Import leads list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Import from CSV or Excel file'**
  String get importLeadsSubtitle;

  /// Export leads list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Export to CSV or Excel'**
  String get exportLeadsSubtitle;

  /// Error message for overlay sync failure
  ///
  /// In en, this message translates to:
  /// **'Failed to sync overlay settings: {error}'**
  String syncOverlayFailed(String error);

  /// Snackbar after clearing dismissed numbers
  ///
  /// In en, this message translates to:
  /// **'Dismissed numbers cleared.'**
  String get dismissedNumbersCleared;

  /// Generic error snackbar
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// Security settings section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// PIN lock toggle title
  ///
  /// In en, this message translates to:
  /// **'PIN Lock'**
  String get pinLock;

  /// PIN lock toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Require PIN or biometric to open the app'**
  String get pinLockSubtitle;

  /// Set up PIN list tile title
  ///
  /// In en, this message translates to:
  /// **'Set up PIN'**
  String get setupPin;

  /// Set up PIN list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get setupPinSubtitle;

  /// Change PIN list tile title
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// Change PIN list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your 4-digit PIN'**
  String get changePinSubtitle;

  /// Disable PIN list tile title
  ///
  /// In en, this message translates to:
  /// **'Disable PIN'**
  String get disablePin;

  /// Confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Disable PIN lock?'**
  String get disablePinConfirmTitle;

  /// Confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Your app data will not be PIN-protected. The database encryption key remains unchanged.'**
  String get disablePinConfirmBody;

  /// Disable action button
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Auto-lock setting title
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get autoLock;

  /// Auto-lock setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Lock after app goes to background'**
  String get autoLockSubtitle;

  /// Auto-lock option: immediately
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get autoLockImmediate;

  /// Auto-lock option: 30 seconds
  ///
  /// In en, this message translates to:
  /// **'After 30 seconds'**
  String get autoLock30s;

  /// Auto-lock option: 1 minute
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get autoLock1m;

  /// Auto-lock option: 5 minutes
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get autoLock5m;

  /// Auto-lock option: 15 minutes
  ///
  /// In en, this message translates to:
  /// **'After 15 minutes'**
  String get autoLock15m;

  /// Lock the app immediately from settings
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockNow;

  /// Language settings section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language picker list tile title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Language picker list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get languageSubtitle;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Amharic language option
  ///
  /// In en, this message translates to:
  /// **'አማርኛ (Amharic)'**
  String get languageAmharic;

  /// Calendar settings section title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Calendar display mode picker title
  ///
  /// In en, this message translates to:
  /// **'Calendar display'**
  String get calendarDisplay;

  /// Calendar display mode picker subtitle
  ///
  /// In en, this message translates to:
  /// **'Date format used throughout the app'**
  String get calendarDisplaySubtitle;

  /// Ethiopian calendar display mode
  ///
  /// In en, this message translates to:
  /// **'Ethiopian (ዓ.ም)'**
  String get calendarEthiopian;

  /// Gregorian calendar display mode
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get calendarGregorian;

  /// Show both calendar systems
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get calendarBoth;

  /// Lock screen main title
  ///
  /// In en, this message translates to:
  /// **'Kiko is locked'**
  String get pinLockedTitle;

  /// Lock screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get pinLockedSubtitle;

  /// PIN setup screen title (step 1)
  ///
  /// In en, this message translates to:
  /// **'Set up PIN'**
  String get pinSetupTitle;

  /// PIN setup screen title (step 2)
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinConfirmTitle;

  /// PIN change screen title (step 1)
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get pinChangeTitle;

  /// PIN change screen title (step 2)
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get pinChangeConfirmTitle;

  /// PIN setup step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN to protect your data'**
  String get pinSetupSubtitle;

  /// PIN setup step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Re-enter your PIN to confirm'**
  String get pinConfirmSubtitle;

  /// Error when PIN confirmation doesn't match
  ///
  /// In en, this message translates to:
  /// **'PINs didn\'t match. Please try again.'**
  String get pinMismatch;

  /// Error when PIN storage fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save PIN. Please try again.'**
  String get pinSaveFailed;

  /// Wrong PIN entered; shows remaining attempts
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. {count} attempt{plural} remaining.'**
  String pinIncorrect(int count, String plural);

  /// Lockout message shown below PIN dots
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {time}'**
  String pinTooManyAttempts(String time);

  /// Forgot PIN button on lock screen
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get pinForgot;

  /// Forgot PIN dialog title
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get pinForgotTitle;

  /// Forgot PIN dialog body
  ///
  /// In en, this message translates to:
  /// **'PIN reset via email OTP will be available after account setup (Phase 9). For now, please uninstall and reinstall the app to reset all data.'**
  String get pinForgotBody;

  /// Snackbar after PIN is set up
  ///
  /// In en, this message translates to:
  /// **'PIN lock enabled'**
  String get pinEnabled;

  /// Snackbar after PIN is disabled
  ///
  /// In en, this message translates to:
  /// **'PIN lock disabled'**
  String get pinDisabled;

  /// Snackbar after PIN is changed
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get pinChanged;

  /// Biometric authentication prompt message
  ///
  /// In en, this message translates to:
  /// **'Unlock Kiko'**
  String get biometricPrompt;

  /// Ethiopian date picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get ethiopianDatePickerTitle;

  /// Today label in date pickers
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Shows the Gregorian equivalent in the ET picker
  ///
  /// In en, this message translates to:
  /// **'Gregorian: {date}'**
  String gregorianDate(String date);
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
