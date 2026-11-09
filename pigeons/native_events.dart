// Pigeon IDL — Native → Flutter event callbacks (FlutterApi)
// Kotlin calls these methods on the Flutter side.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/native_events.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/NativeEvents.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// Flutter API implemented by Dart; Kotlin sends results from native dialogs.
@FlutterApi()
abstract class NativeEventsFlutterApi {
  /// Called when the user dismisses the "Is this a lead?" dialog shown
  /// during/after a call from an unknown number.
  ///
  /// [e164] is the normalised caller number.
  /// [addAsLead] is true when the user tapped "Yes, add as lead".
  void onUnknownCallerDialogResult(String e164, bool addAsLead);

  /// Called when the user submits the post-call "Set Lead Status" dialog.
  ///
  /// [e164] is the normalised number of the lead.
  /// [newStatusCode] is the code selected by the user, or null if the dialog
  /// was dismissed without a selection.
  void onPostCallDialogResult(String e164, String? newStatusCode);
}
