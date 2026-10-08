import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Newaka'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In de, this message translates to:
  /// **'Nur eine weitere Abfallkalender-App'**
  String get appTagline;

  /// No description provided for @tabHome.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get tabHome;

  /// No description provided for @tabCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get tabCalendar;

  /// No description provided for @tabSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get tabSettings;

  /// No description provided for @nextPickup.
  ///
  /// In de, this message translates to:
  /// **'Nächste Abholung'**
  String get nextPickup;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In de, this message translates to:
  /// **'in {count} Tagen'**
  String inDays(int count);

  /// No description provided for @noUpcoming.
  ///
  /// In de, this message translates to:
  /// **'Keine anstehenden Termine'**
  String get noUpcoming;

  /// No description provided for @noUpcomingHint.
  ///
  /// In de, this message translates to:
  /// **'Alle importierten Termine liegen in der Vergangenheit. Importiere den Kalender für das neue Jahr.'**
  String get noUpcomingHint;

  /// No description provided for @emptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Termine'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In de, this message translates to:
  /// **'Importiere den Abfuhrkalender deines Landkreises als CSV- oder ICS-Datei, oder trage die ICS-Adresse ein.'**
  String get emptyBody;

  /// No description provided for @importFile.
  ///
  /// In de, this message translates to:
  /// **'Datei importieren'**
  String get importFile;

  /// No description provided for @enterUrl.
  ///
  /// In de, this message translates to:
  /// **'URL eintragen'**
  String get enterUrl;

  /// No description provided for @urlDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'ICS-Adresse'**
  String get urlDialogTitle;

  /// No description provided for @urlDialogHint.
  ///
  /// In de, this message translates to:
  /// **'https://…'**
  String get urlDialogHint;

  /// No description provided for @urlInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine gültige http- oder https-Adresse eingeben.'**
  String get urlInvalid;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @importPreviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Import prüfen'**
  String get importPreviewTitle;

  /// No description provided for @importPreviewSelection.
  ///
  /// In de, this message translates to:
  /// **'{selected} von {total} Terminen, {types} von {typesTotal} Abfuhrarten'**
  String importPreviewSelection(
    int selected,
    int total,
    int types,
    int typesTotal,
  );

  /// No description provided for @importPreviewChooseTypes.
  ///
  /// In de, this message translates to:
  /// **'Welche Abfuhrarten sollen importiert werden?'**
  String get importPreviewChooseTypes;

  /// No description provided for @importTypeCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Termine'**
  String importTypeCount(int count);

  /// No description provided for @importPreviewRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum {from} bis {to}'**
  String importPreviewRange(String from, String to);

  /// No description provided for @importModeMerge.
  ///
  /// In de, this message translates to:
  /// **'Zusammenführen'**
  String get importModeMerge;

  /// No description provided for @importModeReplace.
  ///
  /// In de, this message translates to:
  /// **'Bestehende ersetzen'**
  String get importModeReplace;

  /// No description provided for @importSuccess.
  ///
  /// In de, this message translates to:
  /// **'{count} Termine importiert'**
  String importSuccess(int count);

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importFailed;

  /// No description provided for @warnings.
  ///
  /// In de, this message translates to:
  /// **'Hinweise'**
  String get warnings;

  /// No description provided for @permissionDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen erlauben'**
  String get permissionDialogTitle;

  /// No description provided for @permissionDialogBody.
  ///
  /// In de, this message translates to:
  /// **'Damit dich die App vor der Abholung erinnern kann, braucht sie die Berechtigung für Benachrichtigungen.'**
  String get permissionDialogBody;

  /// No description provided for @permissionDialogAllow.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get permissionDialogAllow;

  /// No description provided for @calendarToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get calendarToday;

  /// No description provided for @legend.
  ///
  /// In de, this message translates to:
  /// **'Legende'**
  String get legend;

  /// No description provided for @noPickupsThisDay.
  ///
  /// In de, this message translates to:
  /// **'Keine Abholung an diesem Tag'**
  String get noPickupsThisDay;

  /// No description provided for @sectionReminders.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get sectionReminders;

  /// No description provided for @sectionWasteTypes.
  ///
  /// In de, this message translates to:
  /// **'Abfuhrarten'**
  String get sectionWasteTypes;

  /// No description provided for @sectionData.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get sectionData;

  /// No description provided for @sectionAbout.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get sectionAbout;

  /// No description provided for @reminderDayOf.
  ///
  /// In de, this message translates to:
  /// **'Am Abholtag'**
  String get reminderDayOf;

  /// No description provided for @reminderDayBefore.
  ///
  /// In de, this message translates to:
  /// **'Am Vortag'**
  String get reminderDayBefore;

  /// No description provided for @reminderTwoDaysBefore.
  ///
  /// In de, this message translates to:
  /// **'Zwei Tage vorher'**
  String get reminderTwoDaysBefore;

  /// No description provided for @reminderAt.
  ///
  /// In de, this message translates to:
  /// **'um {time}'**
  String reminderAt(String time);

  /// No description provided for @addReminder.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung hinzufügen'**
  String get addReminder;

  /// No description provided for @maxRemindersReached.
  ///
  /// In de, this message translates to:
  /// **'Maximal 5 Erinnerungen'**
  String get maxRemindersReached;

  /// No description provided for @sendTestNotification.
  ///
  /// In de, this message translates to:
  /// **'Test-Benachrichtigung senden'**
  String get sendTestNotification;

  /// No description provided for @testNotificationTitle.
  ///
  /// In de, this message translates to:
  /// **'Test'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In de, this message translates to:
  /// **'So sehen deine Erinnerungen aus.'**
  String get testNotificationBody;

  /// No description provided for @permissionGranted.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen erlaubt'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen nicht erlaubt'**
  String get permissionDenied;

  /// No description provided for @permissionUnknown.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung noch nicht angefragt'**
  String get permissionUnknown;

  /// No description provided for @requestPermission.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung anfragen'**
  String get requestPermission;

  /// No description provided for @permissionDeniedHint.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube Benachrichtigungen in den Systemeinstellungen deines Geräts, falls die Anfrage nicht mehr erscheint.'**
  String get permissionDeniedHint;

  /// No description provided for @requestExactAlarms.
  ///
  /// In de, this message translates to:
  /// **'Exakte Alarme erlauben'**
  String get requestExactAlarms;

  /// No description provided for @exactAlarmsMissing.
  ///
  /// In de, this message translates to:
  /// **'Exakte Alarme sind nicht erlaubt, Erinnerungen können einige Minuten verzögert sein.'**
  String get exactAlarmsMissing;

  /// No description provided for @typeActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get typeActive;

  /// No description provided for @typeHidden.
  ///
  /// In de, this message translates to:
  /// **'Ausgeblendet'**
  String get typeHidden;

  /// No description provided for @editWasteType.
  ///
  /// In de, this message translates to:
  /// **'Abfuhrart bearbeiten'**
  String get editWasteType;

  /// No description provided for @deleteWasteType.
  ///
  /// In de, this message translates to:
  /// **'Abfuhrart löschen'**
  String get deleteWasteType;

  /// No description provided for @deleteWasteTypeConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} löschen?'**
  String deleteWasteTypeConfirmTitle(String name);

  /// No description provided for @deleteWasteTypeConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Die Abfuhrart hat keine Termine.} =1{Die Abfuhrart und 1 Termin werden entfernt.} other{Die Abfuhrart und {count} Termine werden entfernt.}} Ein Abo-Refresh legt sie nicht wieder an.'**
  String deleteWasteTypeConfirmBody(int count);

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @color.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In de, this message translates to:
  /// **'Symbol'**
  String get icon;

  /// No description provided for @subscription.
  ///
  /// In de, this message translates to:
  /// **'URL-Abo'**
  String get subscription;

  /// No description provided for @subscriptionNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Abo eingerichtet'**
  String get subscriptionNone;

  /// No description provided for @subscriptionLastFetched.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt geladen: {when}'**
  String subscriptionLastFetched(String when);

  /// No description provided for @subscriptionNeverFetched.
  ///
  /// In de, this message translates to:
  /// **'Noch nie geladen'**
  String get subscriptionNeverFetched;

  /// No description provided for @subscriptionError.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String subscriptionError(String message);

  /// No description provided for @refreshNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt aktualisieren'**
  String get refreshNow;

  /// No description provided for @removeSubscription.
  ///
  /// In de, this message translates to:
  /// **'Abo entfernen'**
  String get removeSubscription;

  /// No description provided for @loadSampleData.
  ///
  /// In de, this message translates to:
  /// **'Beispieldaten laden'**
  String get loadSampleData;

  /// No description provided for @loadSampleDataHint.
  ///
  /// In de, this message translates to:
  /// **'Fiktiver Kalender für Musterstadt, zwölf Monate ab heute'**
  String get loadSampleDataHint;

  /// No description provided for @deleteAllData.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen'**
  String get deleteAllData;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich alles löschen?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Termine, Abfuhrarten und das URL-Abo werden entfernt. Erinnerungen werden abgesagt.'**
  String get deleteAllConfirmBody;

  /// No description provided for @dataDeleted.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten gelöscht'**
  String get dataDeleted;

  /// No description provided for @corruptDataNotice.
  ///
  /// In de, this message translates to:
  /// **'Die gespeicherten Daten waren beschädigt und wurden zurückgesetzt. Bitte importiere den Kalender erneut.'**
  String get corruptDataNotice;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @licenses.
  ///
  /// In de, this message translates to:
  /// **'Lizenzen'**
  String get licenses;

  /// No description provided for @privacyNote.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben auf diesem Gerät. Es werden keine Daten an Dritte gesendet.'**
  String get privacyNote;

  /// No description provided for @pickupNoteDefault.
  ///
  /// In de, this message translates to:
  /// **'Tonne rechtzeitig bereitstellen'**
  String get pickupNoteDefault;
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
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
