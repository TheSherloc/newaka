// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Newaka';

  @override
  String get appTagline => 'Nur eine weitere Abfallkalender-App';

  @override
  String get tabHome => 'Start';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get nextPickup => 'Nächste Abholung';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String inDays(int count) {
    return 'in $count Tagen';
  }

  @override
  String get noUpcoming => 'Keine anstehenden Termine';

  @override
  String get noUpcomingHint =>
      'Alle importierten Termine liegen in der Vergangenheit. Importiere den Kalender für das neue Jahr.';

  @override
  String get emptyTitle => 'Noch keine Termine';

  @override
  String get emptyBody =>
      'Importiere den Abfuhrkalender deines Landkreises als CSV- oder ICS-Datei, oder trage die ICS-Adresse ein.';

  @override
  String get importFile => 'Datei importieren';

  @override
  String get enterUrl => 'URL eintragen';

  @override
  String get urlDialogTitle => 'ICS-Adresse';

  @override
  String get urlDialogHint => 'https://…';

  @override
  String get urlInvalid =>
      'Bitte eine gültige http- oder https-Adresse eingeben.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get importPreviewTitle => 'Import prüfen';

  @override
  String importPreviewSummary(int count, int types) {
    return '$count Termine, $types Abfuhrarten';
  }

  @override
  String importPreviewRange(String from, String to) {
    return 'Zeitraum $from bis $to';
  }

  @override
  String get importModeMerge => 'Zusammenführen';

  @override
  String get importModeReplace => 'Bestehende ersetzen';

  @override
  String importSuccess(int count) {
    return '$count Termine importiert';
  }

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get warnings => 'Hinweise';

  @override
  String get permissionDialogTitle => 'Erinnerungen erlauben';

  @override
  String get permissionDialogBody =>
      'Damit dich die App vor der Abholung erinnern kann, braucht sie die Berechtigung für Benachrichtigungen.';

  @override
  String get permissionDialogAllow => 'Weiter';

  @override
  String get calendarToday => 'Heute';

  @override
  String get legend => 'Legende';

  @override
  String get noPickupsThisDay => 'Keine Abholung an diesem Tag';

  @override
  String get sectionReminders => 'Erinnerungen';

  @override
  String get sectionWasteTypes => 'Abfuhrarten';

  @override
  String get sectionData => 'Daten';

  @override
  String get sectionAbout => 'Über';

  @override
  String get reminderDayOf => 'Am Abholtag';

  @override
  String get reminderDayBefore => 'Am Vortag';

  @override
  String get reminderTwoDaysBefore => 'Zwei Tage vorher';

  @override
  String reminderAt(String time) {
    return 'um $time';
  }

  @override
  String get addReminder => 'Erinnerung hinzufügen';

  @override
  String get maxRemindersReached => 'Maximal 5 Erinnerungen';

  @override
  String get sendTestNotification => 'Test-Benachrichtigung senden';

  @override
  String get testNotificationTitle => 'Test';

  @override
  String get testNotificationBody => 'So sehen deine Erinnerungen aus.';

  @override
  String get permissionGranted => 'Benachrichtigungen erlaubt';

  @override
  String get permissionDenied => 'Benachrichtigungen nicht erlaubt';

  @override
  String get permissionUnknown => 'Berechtigung noch nicht angefragt';

  @override
  String get requestPermission => 'Berechtigung anfragen';

  @override
  String get permissionDeniedHint =>
      'Bitte erlaube Benachrichtigungen in den Systemeinstellungen deines Geräts, falls die Anfrage nicht mehr erscheint.';

  @override
  String get requestExactAlarms => 'Exakte Alarme erlauben';

  @override
  String get exactAlarmsMissing =>
      'Exakte Alarme sind nicht erlaubt, Erinnerungen können einige Minuten verzögert sein.';

  @override
  String get notifyForType => 'Erinnern';

  @override
  String get editWasteType => 'Abfuhrart bearbeiten';

  @override
  String get name => 'Name';

  @override
  String get color => 'Farbe';

  @override
  String get icon => 'Symbol';

  @override
  String get subscription => 'URL-Abo';

  @override
  String get subscriptionNone => 'Kein Abo eingerichtet';

  @override
  String subscriptionLastFetched(String when) {
    return 'Zuletzt geladen: $when';
  }

  @override
  String get subscriptionNeverFetched => 'Noch nie geladen';

  @override
  String subscriptionError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get refreshNow => 'Jetzt aktualisieren';

  @override
  String get removeSubscription => 'Abo entfernen';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllConfirmTitle => 'Wirklich alles löschen?';

  @override
  String get deleteAllConfirmBody =>
      'Alle Termine, Abfuhrarten und das URL-Abo werden entfernt. Erinnerungen werden abgesagt.';

  @override
  String get dataDeleted => 'Alle Daten gelöscht';

  @override
  String get corruptDataNotice =>
      'Die gespeicherten Daten waren beschädigt und wurden zurückgesetzt. Bitte importiere den Kalender erneut.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get licenses => 'Lizenzen';

  @override
  String get privacyNote =>
      'Alle Daten bleiben auf diesem Gerät. Es werden keine Daten an Dritte gesendet.';

  @override
  String get pickupNoteDefault => 'Tonne rechtzeitig bereitstellen';
}
