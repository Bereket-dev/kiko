// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kiko';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get skip => 'Skip';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get search => 'Search';

  @override
  String get leads => 'Leads';

  @override
  String get recentCalls => 'Recent Calls';

  @override
  String get callPlan => 'Call Plan';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get importLeads => 'Import Leads';

  @override
  String get exportLeads => 'Export Leads';

  @override
  String get permissions => 'Permissions';

  @override
  String get overlay => 'Overlay';

  @override
  String get calls => 'Calls';

  @override
  String get data => 'Data';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get showCallerOverlay => 'Show caller overlay';

  @override
  String get showCallerOverlaySubtitle =>
      'Display lead info during incoming calls';

  @override
  String get showCallHistory => 'Show call history';

  @override
  String get showCallHistorySubtitle =>
      'Include last note and last call date in overlay';

  @override
  String get askUnknownCallers => 'Ask about unknown callers';

  @override
  String get askUnknownCallersSubtitle =>
      'Show \"Is this a lead?\" dialog for unrecognised numbers';

  @override
  String get resetDismissedNumbers => 'Reset dismissed numbers';

  @override
  String get resetDismissedNumbersSubtitle =>
      'Start asking again about previously dismissed callers';

  @override
  String get resetDismissedNumbersConfirmTitle => 'Reset dismissed numbers?';

  @override
  String get resetDismissedNumbersConfirmBody =>
      'Kiko will start asking again whether unknown callers you previously dismissed are leads.';

  @override
  String get viewRecentCalls => 'Recent calls';

  @override
  String get viewRecentCallsSubtitle => 'View call log and add leads';

  @override
  String get viewPermissions => 'Permissions';

  @override
  String get viewPermissionsSubtitle => 'Grant or review required permissions';

  @override
  String get importLeadsSubtitle => 'Import from CSV or Excel file';

  @override
  String get exportLeadsSubtitle => 'Export to CSV or Excel';

  @override
  String syncOverlayFailed(String error) {
    return 'Failed to sync overlay settings: $error';
  }

  @override
  String get dismissedNumbersCleared => 'Dismissed numbers cleared.';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get security => 'Security';

  @override
  String get pinLock => 'PIN Lock';

  @override
  String get pinLockSubtitle => 'Require PIN or biometric to open the app';

  @override
  String get setupPin => 'Set up PIN';

  @override
  String get setupPinSubtitle => 'Choose a 4-digit PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinSubtitle => 'Update your 4-digit PIN';

  @override
  String get disablePin => 'Disable PIN';

  @override
  String get disablePinConfirmTitle => 'Disable PIN lock?';

  @override
  String get disablePinConfirmBody =>
      'Your app data will not be PIN-protected. The database encryption key remains unchanged.';

  @override
  String get disable => 'Disable';

  @override
  String get autoLock => 'Auto-lock';

  @override
  String get autoLockSubtitle => 'Lock after app goes to background';

  @override
  String get autoLockImmediate => 'Immediately';

  @override
  String get autoLock30s => 'After 30 seconds';

  @override
  String get autoLock1m => 'After 1 minute';

  @override
  String get autoLock5m => 'After 5 minutes';

  @override
  String get autoLock15m => 'After 15 minutes';

  @override
  String get lockNow => 'Lock now';

  @override
  String get language => 'Language';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSubtitle => 'App display language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ (Amharic)';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarDisplay => 'Calendar display';

  @override
  String get calendarDisplaySubtitle => 'Date format used throughout the app';

  @override
  String get calendarEthiopian => 'Ethiopian (ዓ.ም)';

  @override
  String get calendarGregorian => 'Gregorian';

  @override
  String get calendarBoth => 'Both';

  @override
  String get pinLockedTitle => 'Kiko is locked';

  @override
  String get pinLockedSubtitle => 'Enter your PIN to continue';

  @override
  String get pinSetupTitle => 'Set up PIN';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get pinChangeTitle => 'Enter new PIN';

  @override
  String get pinChangeConfirmTitle => 'Confirm new PIN';

  @override
  String get pinSetupSubtitle => 'Choose a 4-digit PIN to protect your data';

  @override
  String get pinConfirmSubtitle => 'Re-enter your PIN to confirm';

  @override
  String get pinMismatch => 'PINs didn\'t match. Please try again.';

  @override
  String get pinSaveFailed => 'Failed to save PIN. Please try again.';

  @override
  String pinIncorrect(int count, String plural) {
    return 'Incorrect PIN. $count attempt$plural remaining.';
  }

  @override
  String pinTooManyAttempts(String time) {
    return 'Too many attempts. Try again in $time';
  }

  @override
  String get pinForgot => 'Forgot PIN';

  @override
  String get pinForgotTitle => 'Forgot PIN?';

  @override
  String get pinForgotBody =>
      'PIN reset via email OTP will be available after account setup (Phase 9). For now, please uninstall and reinstall the app to reset all data.';

  @override
  String get pinEnabled => 'PIN lock enabled';

  @override
  String get pinDisabled => 'PIN lock disabled';

  @override
  String get pinChanged => 'PIN updated';

  @override
  String get biometricPrompt => 'Unlock Kiko';

  @override
  String get ethiopianDatePickerTitle => 'Select date';

  @override
  String get today => 'Today';

  @override
  String gregorianDate(String date) {
    return 'Gregorian: $date';
  }
}
