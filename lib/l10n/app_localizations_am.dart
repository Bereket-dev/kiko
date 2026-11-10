// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ኪኮ';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get delete => 'አጥፋ';

  @override
  String get edit => 'አርትዕ';

  @override
  String get confirm => 'አረጋግጥ';

  @override
  String get skip => 'ዝለል';

  @override
  String get ok => 'እሺ';

  @override
  String get done => 'ተጠናቋል';

  @override
  String get search => 'ፈልግ';

  @override
  String get leads => 'ሊድስ';

  @override
  String get recentCalls => 'የቅርብ ጊዜ ጥሪዎች';

  @override
  String get callPlan => 'የጥሪ ዕቅድ';

  @override
  String get export => 'ወደ ውጭ ላክ';

  @override
  String get import => 'አስገባ';

  @override
  String get importLeads => 'ሊድ አስገባ';

  @override
  String get exportLeads => 'ሊድ ወደ ውጭ ላክ';

  @override
  String get permissions => 'ፈቃዶች';

  @override
  String get overlay => 'ኦቨርሌይ';

  @override
  String get calls => 'ጥሪዎች';

  @override
  String get data => 'ዳታ';

  @override
  String get about => 'ስለ';

  @override
  String get version => 'ስሪት';

  @override
  String get showCallerOverlay => 'የደዋይ ኦቨርሌይ አሳይ';

  @override
  String get showCallerOverlaySubtitle => 'በሚደርስ ጥሪ ወቅት የሊድ መረጃ ያሳያል';

  @override
  String get showCallHistory => 'የጥሪ ታሪክ አሳይ';

  @override
  String get showCallHistorySubtitle => 'የመጨረሻ ማስታወሻ እና የጥሪ ቀን ያካትታል';

  @override
  String get askUnknownCallers => 'ስለ ያልታወቁ ደዋዮች ጠይቅ';

  @override
  String get askUnknownCallersSubtitle => '\"ይህ ሊድ ነው?\" ሳጥን ለማይታወቁ ቁጥሮች ያሳያል';

  @override
  String get resetDismissedNumbers => 'የተዘጉ ቁጥሮችን ዳግም ጫን';

  @override
  String get resetDismissedNumbersSubtitle => 'ቀደም ሲል ስለዘጋቸው ደዋዮች ዳግም ይጠይቃል';

  @override
  String get resetDismissedNumbersConfirmTitle => 'የተዘጉ ቁጥሮችን ዳግም ጫን?';

  @override
  String get resetDismissedNumbersConfirmBody =>
      'ቀደም ሲል ስለዘጋቸው ያልታወቁ ደዋዮች ሊድ ናቸው ወይ ዳግም ይጠይቃል።';

  @override
  String get viewRecentCalls => 'የቅርብ ጊዜ ጥሪዎች';

  @override
  String get viewRecentCallsSubtitle => 'የጥሪ ምዝግብ ይፈትሹ እና ሊድ ያክሉ';

  @override
  String get viewPermissions => 'ፈቃዶች';

  @override
  String get viewPermissionsSubtitle => 'የሚፈለጉ ፈቃዶችን ያሰጥ ወይም ይፈትሹ';

  @override
  String get importLeadsSubtitle => 'ከ CSV ወይም Excel ፋይል አስገባ';

  @override
  String get exportLeadsSubtitle => 'ወደ CSV ወይም Excel ወደ ውጭ ላክ';

  @override
  String syncOverlayFailed(String error) {
    return 'የኦቨርሌይ ቅንብሮችን ማሳመን አልተቻለም: $error';
  }

  @override
  String get dismissedNumbersCleared => 'የተዘጉ ቁጥሮች ተሰርዘዋል።';

  @override
  String errorGeneric(String error) {
    return 'ስህተት: $error';
  }

  @override
  String get security => 'ደህንነት';

  @override
  String get pinLock => 'PIN መቆለፊያ';

  @override
  String get pinLockSubtitle => 'መተግበሪያውን ለመክፈት PIN ወይም ባዮሜትሪክ ያስፈልጋል';

  @override
  String get setupPin => 'PIN አዘጋጅ';

  @override
  String get setupPinSubtitle => '4-አሃዝ PIN ምረጥ';

  @override
  String get changePin => 'PIN ቀይር';

  @override
  String get changePinSubtitle => '4-አሃዝ PIN አዘምን';

  @override
  String get disablePin => 'PIN አሰናክል';

  @override
  String get disablePinConfirmTitle => 'PIN መቆለፊያ ያሰናክሉ?';

  @override
  String get disablePinConfirmBody =>
      'የመተግበሪያ ዳታዎ በ PIN አይጠበቅም። የዳታቤዝ ምስጠራ ቁልፍ ሳይቀየር ይቆያል።';

  @override
  String get disable => 'አሰናክል';

  @override
  String get autoLock => 'ራስ-ቆለፋ';

  @override
  String get autoLockSubtitle => 'ወደ ኋላ ሲሄድ ቆልፍ';

  @override
  String get autoLockImmediate => 'ወዲያውኑ';

  @override
  String get autoLock30s => 'ከ30 ሰኮንድ በኋላ';

  @override
  String get autoLock1m => 'ከ1 ደቂቃ በኋላ';

  @override
  String get autoLock5m => 'ከ5 ደቂቃዎች በኋላ';

  @override
  String get autoLock15m => 'ከ15 ደቂቃዎች በኋላ';

  @override
  String get lockNow => 'አሁን ቆልፍ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get languageLabel => 'ቋንቋ';

  @override
  String get languageSubtitle => 'የመተግበሪያ ማሳያ ቋንቋ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get calendar => 'የቀን አቆጣጠር';

  @override
  String get calendarDisplay => 'የቀን አቆጣጠር ማሳያ';

  @override
  String get calendarDisplaySubtitle => 'በመላው መተግበሪያ ጥቅም ላይ የሚውለው የቀን ቅርጸት';

  @override
  String get calendarEthiopian => 'የኢትዮጵያ (ዓ.ም)';

  @override
  String get calendarGregorian => 'ጎርጎሳዊ';

  @override
  String get calendarBoth => 'ሁለቱም';

  @override
  String get pinLockedTitle => 'ኪኮ ተቆልፏል';

  @override
  String get pinLockedSubtitle => 'ለቀጠሉ PIN ያስገቡ';

  @override
  String get pinSetupTitle => 'PIN አዘጋጅ';

  @override
  String get pinConfirmTitle => 'PIN አረጋግጥ';

  @override
  String get pinChangeTitle => 'አዲስ PIN ያስገቡ';

  @override
  String get pinChangeConfirmTitle => 'አዲስ PIN አረጋግጥ';

  @override
  String get pinSetupSubtitle => 'ዳታዎን ለመጠበቅ 4-አሃዝ PIN ምረጥ';

  @override
  String get pinConfirmSubtitle => 'ለማረጋገጥ PIN ዳግም ያስገቡ';

  @override
  String get pinMismatch => 'PINዎቹ አልተዛመዱም። እባክዎን ዳግም ሞክሩ።';

  @override
  String get pinSaveFailed => 'PIN ማስቀመጥ አልተቻለም። እባክዎን ዳግም ሞክሩ።';

  @override
  String pinIncorrect(int count, String plural) {
    return 'PIN ትክክል አይደለም። $count ሙከራ$plural ቀርቷል።';
  }

  @override
  String pinTooManyAttempts(String time) {
    return 'ብዙ ሙከራዎች። ከ$time በኋላ ዳግም ሞክሩ';
  }

  @override
  String get pinForgot => 'PIN ረሱ?';

  @override
  String get pinForgotTitle => 'PIN ረሱ?';

  @override
  String get pinForgotBody =>
      'PIN ዳግም ማስጀመር በ ኢሜይል OTP (Phase 9) ይሆናል። አሁን፣ ሁሉንም ዳታ ለማስጀመር መተግበሪያውን አወርዶ ዳግም ይጫኑ።';

  @override
  String get pinEnabled => 'PIN መቆለፊያ ነቅቷል';

  @override
  String get pinDisabled => 'PIN መቆለፊያ ቆሟል';

  @override
  String get pinChanged => 'PIN ተዘምኗል';

  @override
  String get biometricPrompt => 'ኪኮን ክፈት';

  @override
  String get ethiopianDatePickerTitle => 'ቀን ምረጥ';

  @override
  String get today => 'ዛሬ';

  @override
  String gregorianDate(String date) {
    return 'ጎርጎሳዊ: $date';
  }
}
