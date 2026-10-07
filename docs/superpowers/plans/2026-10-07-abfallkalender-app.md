# Abfallkalender App – Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eine Flutter-App für iOS und Android, die Abfuhrtermine aus CSV, ICS-Datei oder ICS-URL importiert, in Kalender und Terminliste zeigt und per lokal geplanter Benachrichtigung erinnert.

**Architecture:** Ein Flutter-Projekt mit feature-orientierter Struktur. Parser, Merge-Logik und Benachrichtigungsplanung sind reine Dart-Klassen hinter schmalen Interfaces (`NotificationGateway`, `HttpSource`, `Clock`, Repositories) und werden mit Fakes getestet. Riverpod 3 hält den Zustand, die UI ist zustandslos bis auf lokale Eingaben. Persistenz als JSON-Datei plus SharedPreferences.

**Tech Stack:** Flutter 3.47.6 stable (Dart 3.13), flutter_riverpod 3.x, flutter_local_notifications 22.x, timezone 0.11, flutter_timezone 5.x, table_calendar 3.3, file_picker 13.x, http 1.x, shared_preferences 2.5, path_provider 2.1, intl, flutter_localizations, package_info_plus.

**Spec:** `docs/superpowers/specs/2026-10-07-abfallkalender-app-design.md`

## Global Constraints

- Flutter stable 3.47.6, Dart SDK `^3.13.0`. Keine Code-Generierung außer Flutters eingebautem `gen-l10n`.
- Abhängigkeiten nur die oben genannten. Kein Firebase, kein Backend, keine Nutzerkonten.
- UI-Texte ausschließlich über ARB (`lib/l10n/app_de.arb`, Klasse `AppLocalizations`). Einzige Ausnahme: Benachrichtigungstexte im reinen Dart-Scheduler (Deutsch, Konstanten in `reminder_scheduler.dart`) und Fehlertexte der Parser (Deutsch, Konstanten in den Parser-Dateien).
- Reine Dart-Dateien unter `domain/`, `core/`, `data/models/` importieren nie `package:flutter`.
- Fehler werden als `Result<T>` zurückgegeben, nie als Exception bis in die UI.
- Standard-Erinnerungen: Vortag 18:00 und Abholtag 07:00. Maximal 5 Regeln. `daysBefore` nur 0, 1 oder 2.
- Benachrichtigungslimit: iOS 60 plus Hinweis-Benachrichtigung (ID 1), Android 200. Neuplanung bei App-Start, nach Import, nach Regel-/Abfuhrart-Änderung, bei Rückkehr in den Vordergrund nach mehr als 12 Stunden.
- URL-Abo: HTTP GET, Timeout 20 Sekunden, nur `http`/`https`, Auto-Refresh nach 24 Stunden, Modus Zusammenführen, keine Fehler-Popups.
- Standardfarben: bio Braun `0xFF6D4C41`, rest/hausmuell Dunkelgrau `0xFF455A64`, wertstoff/gelb/verpackung/plastik Gelb `0xFFF9A825`, papier/karton Blau `0xFF1E88E5`, problem/schadstoff/sonder Rot `0xFFD32F2F`, glas Grün `0xFF2E7D32`, sperr Violett `0xFF6A1B9A`, sonst Neutralgrau `0xFF78909C`.
- Alle Daten bleiben auf dem Gerät. JSON-Datei `data.json` atomar schreiben (temp, dann umbenennen), beschädigte Datei nach `data.json.broken` sichern.
- Commits nach jeder Aufgabe. Commit-Messages enden mit `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Befehle in diesem Plan sind für PowerShell auf Windows geschrieben. `flutter` liegt nach Task 1 unter `C:\src\flutter\bin`.

## Review Focus

1. ICS-Ganztagsereignis `DTSTART;VALUE=DATE:20260102` muss als 2. Jan. 2026 erkannt werden (Test in Task 6).
2. CSV mit UTF-8-BOM und CRLF-Zeilenenden darf weder die Kopfzeile noch den letzten Datensatz verlieren (Tests in Task 5 und 7).
3. Erinnerungszeit an einem Tag mit Zeitumstellung (29.03.2026, 02:30 existiert nicht) darf den Scheduler nicht abstürzen lassen und muss einen gültigen Zeitpunkt liefern (Test in Task 10).
4. Import einer Datei, deren Termine alle in der Vergangenheit liegen, darf nicht als „keine Daten" behandelt werden: Startseite zeigt „Keine anstehenden Termine", nicht das Onboarding (Test in Task 15).
5. Eine URL, die HTML statt ICS liefert, muss einen verständlichen Fehler setzen und die bestehenden Daten unangetastet lassen (Test in Task 13).

---

### Task 1: Projekt-Setup

**Files:**
- Create: Flutter-Projekt im Repo-Root (`pubspec.yaml`, `lib/main.dart`, `android/`, `ios/`, `analysis_options.yaml`)
- Create: `l10n.yaml`, `lib/l10n/app_de.arb`
- Create: `test/fixtures/augsburg_2026.ics`, `test/fixtures/augsburg_2026.csv`
- Delete: `test/widget_test.dart`, die beiden Beispieldateien im Root

**Interfaces:**
- Produces: lauffähiges Flutter-Projekt `abfallkalender`, alle Abhängigkeiten aufgelöst, Fixtures für spätere Tests.

- [ ] **Step 1: Flutter installieren**

```powershell
git clone -b stable --depth 1 https://github.com/flutter/flutter.git C:\src\flutter
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\src\flutter\bin", "User")
$env:Path += ";C:\src\flutter\bin"
flutter --version
flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
flutter config --no-analytics
flutter doctor
```

Erwartet: `Flutter 3.47.x • channel stable`. `flutter doctor` meldet Android toolchain. Falls „cmdline-tools component is missing": Android Studio öffnen, SDK Manager, Tab „SDK Tools", „Android SDK Command-line Tools (latest)" installieren, dann `flutter doctor --android-licenses`. Fehlende iOS-Toolchain ist auf Windows erwartet.

- [ ] **Step 2: Projekt im bestehenden Ordner anlegen**

```powershell
Set-Location D:\Programming\Abfallkalender
flutter create --project-name abfallkalender --org de.abfallkalender --platforms android,ios .
```

Erwartet: `All done!`. Bestehende `docs/` und `.git/` bleiben unangetastet.

- [ ] **Step 3: Abhängigkeiten hinzufügen**

```powershell
flutter pub add flutter_riverpod flutter_local_notifications timezone flutter_timezone table_calendar file_picker http shared_preferences path_provider package_info_plus
flutter pub add flutter_localizations --sdk=flutter
flutter pub add intl:any
flutter pub add --dev flutter_lints
flutter pub get
```

Erwartet: `Changed N dependencies!` ohne Konflikte.

- [ ] **Step 4: Lokalisierung konfigurieren**

`l10n.yaml` im Root anlegen:

```yaml
arb-dir: lib/l10n
template-arb-file: app_de.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

In `pubspec.yaml` unter `flutter:` ergänzen (neben `uses-material-design: true`):

```yaml
flutter:
  uses-material-design: true
  generate: true
```

`lib/l10n/app_de.arb` anlegen (Vollständige Liste; spätere Tasks nutzen genau diese Schlüssel):

```json
{
  "@@locale": "de",
  "appTitle": "Abfallkalender",
  "tabHome": "Start",
  "tabCalendar": "Kalender",
  "tabSettings": "Einstellungen",
  "nextPickup": "Nächste Abholung",
  "today": "Heute",
  "tomorrow": "Morgen",
  "inDays": "in {count} Tagen",
  "@inDays": {"placeholders": {"count": {"type": "int"}}},
  "noUpcoming": "Keine anstehenden Termine",
  "noUpcomingHint": "Alle importierten Termine liegen in der Vergangenheit. Importiere den Kalender für das neue Jahr.",
  "emptyTitle": "Noch keine Termine",
  "emptyBody": "Importiere den Abfuhrkalender deines Landkreises als CSV- oder ICS-Datei, oder trage die ICS-Adresse ein.",
  "importFile": "Datei importieren",
  "enterUrl": "URL eintragen",
  "urlDialogTitle": "ICS-Adresse",
  "urlDialogHint": "https://…",
  "urlInvalid": "Bitte eine gültige http- oder https-Adresse eingeben.",
  "cancel": "Abbrechen",
  "ok": "OK",
  "save": "Speichern",
  "delete": "Löschen",
  "importPreviewTitle": "Import prüfen",
  "importPreviewSummary": "{count} Termine, {types} Abfuhrarten",
  "@importPreviewSummary": {"placeholders": {"count": {"type": "int"}, "types": {"type": "int"}}},
  "importPreviewRange": "Zeitraum {from} bis {to}",
  "@importPreviewRange": {"placeholders": {"from": {"type": "String"}, "to": {"type": "String"}}},
  "importModeMerge": "Zusammenführen",
  "importModeReplace": "Bestehende ersetzen",
  "importSuccess": "{count} Termine importiert",
  "@importSuccess": {"placeholders": {"count": {"type": "int"}}},
  "importFailed": "Import fehlgeschlagen",
  "warnings": "Hinweise",
  "permissionDialogTitle": "Erinnerungen erlauben",
  "permissionDialogBody": "Damit dich die App vor der Abholung erinnern kann, braucht sie die Berechtigung für Benachrichtigungen.",
  "permissionDialogAllow": "Weiter",
  "calendarToday": "Heute",
  "legend": "Legende",
  "noPickupsThisDay": "Keine Abholung an diesem Tag",
  "sectionReminders": "Erinnerungen",
  "sectionWasteTypes": "Abfuhrarten",
  "sectionData": "Daten",
  "sectionAbout": "Über",
  "reminderDayOf": "Am Abholtag",
  "reminderDayBefore": "Am Vortag",
  "reminderTwoDaysBefore": "Zwei Tage vorher",
  "reminderAt": "um {time}",
  "@reminderAt": {"placeholders": {"time": {"type": "String"}}},
  "addReminder": "Erinnerung hinzufügen",
  "maxRemindersReached": "Maximal 5 Erinnerungen",
  "sendTestNotification": "Test-Benachrichtigung senden",
  "testNotificationTitle": "Test",
  "testNotificationBody": "So sehen deine Erinnerungen aus.",
  "permissionGranted": "Benachrichtigungen erlaubt",
  "permissionDenied": "Benachrichtigungen nicht erlaubt",
  "permissionUnknown": "Berechtigung noch nicht angefragt",
  "requestPermission": "Berechtigung anfragen",
  "exactAlarmsMissing": "Exakte Alarme sind nicht erlaubt, Erinnerungen können einige Minuten verzögert sein.",
  "notifyForType": "Erinnern",
  "editWasteType": "Abfuhrart bearbeiten",
  "name": "Name",
  "color": "Farbe",
  "icon": "Symbol",
  "subscription": "URL-Abo",
  "subscriptionNone": "Kein Abo eingerichtet",
  "subscriptionLastFetched": "Zuletzt geladen: {when}",
  "@subscriptionLastFetched": {"placeholders": {"when": {"type": "String"}}},
  "subscriptionNeverFetched": "Noch nie geladen",
  "subscriptionError": "Fehler: {message}",
  "@subscriptionError": {"placeholders": {"message": {"type": "String"}}},
  "refreshNow": "Jetzt aktualisieren",
  "removeSubscription": "Abo entfernen",
  "deleteAllData": "Alle Daten löschen",
  "deleteAllConfirmTitle": "Wirklich alles löschen?",
  "deleteAllConfirmBody": "Alle Termine, Abfuhrarten und das URL-Abo werden entfernt. Erinnerungen werden abgesagt.",
  "dataDeleted": "Alle Daten gelöscht",
  "corruptDataNotice": "Die gespeicherten Daten waren beschädigt und wurden zurückgesetzt. Bitte importiere den Kalender erneut.",
  "version": "Version {version}",
  "@version": {"placeholders": {"version": {"type": "String"}}},
  "licenses": "Lizenzen",
  "privacyNote": "Alle Daten bleiben auf diesem Gerät. Es werden keine Daten an Dritte gesendet.",
  "pickupNoteDefault": "Tonne rechtzeitig bereitstellen"
}
```

- [ ] **Step 5: Fixtures kopieren, Beispieldateien entfernen, Template-Test löschen**

```powershell
New-Item -ItemType Directory -Force test\fixtures | Out-Null
Copy-Item "Abfuhrtermine für Bobingen Karwendelstraße(2).ics" test\fixtures\augsburg_2026.ics
Copy-Item "Abfuhrtermine für Bobingen Karwendelstraße.csv" test\fixtures\augsburg_2026.csv
Remove-Item "Abfuhrtermine für Bobingen Karwendelstraße(2).ics", "Abfuhrtermine für Bobingen Karwendelstraße.csv"
Remove-Item test\widget_test.dart
```

- [ ] **Step 6: `lib/main.dart` auf Minimum reduzieren**

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Abfallkalender')))));
}
```

- [ ] **Step 7: Prüfen**

```powershell
flutter gen-l10n
flutter analyze
flutter test
```

Erwartet: `No issues found!` und `No tests ran` oder `All tests passed`. `lib/l10n/app_localizations.dart` und `app_localizations_de.dart` existieren.

- [ ] **Step 8: Commit**

```powershell
git add -A
git commit -m "Scaffold Flutter project with dependencies, l10n and fixtures`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Core – Result, Datums-Helfer, Clock

**Files:**
- Create: `lib/core/result.dart`, `lib/core/dates.dart`, `lib/core/clock.dart`
- Test: `test/core/result_test.dart`, `test/core/dates_test.dart`

**Interfaces:**
- Produces: `Result<T>` mit `Ok<T>(value, warnings)` und `Err<T>(message)`; `extension DateOnlyX on DateTime { DateTime get dateOnly; String get isoDate; }`; `int daysBetween(DateTime a, DateTime b)`; `DateTime? parseIsoDate(String)`, `DateTime? parseGermanDate(String)`, `DateTime? parseFlexibleDate(String)`; `abstract class Clock { DateTime now(); }`, `SystemClock`, `FixedClock(DateTime)`.

- [ ] **Step 1: Tests schreiben**

`test/core/result_test.dart`:

```dart
import 'package:abfallkalender/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ok carries value and warnings', () {
    const r = Ok<int>(3, warnings: ['w']);
    expect(r.isOk, isTrue);
    expect(r.when(ok: (v, w) => '$v${w.length}', err: (m) => m), '31');
  });

  test('Err carries message', () {
    const r = Err<int>('kaputt');
    expect(r.isOk, isFalse);
    expect(r.when(ok: (v, w) => 'ok', err: (m) => m), 'kaputt');
  });
}
```

`test/core/dates_test.dart`:

```dart
import 'package:abfallkalender/core/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly strips time', () {
    expect(DateTime(2026, 3, 5, 14, 30).dateOnly, DateTime(2026, 3, 5));
  });

  test('isoDate pads', () {
    expect(DateTime(2026, 1, 2).isoDate, '2026-01-02');
  });

  test('daysBetween across DST switch is calendar days', () {
    expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(daysBetween(DateTime(2026, 3, 30), DateTime(2026, 3, 28)), -2);
  });

  test('parseIsoDate', () {
    expect(parseIsoDate('2026-01-02'), DateTime(2026, 1, 2));
    expect(parseIsoDate('2026-13-02'), isNull);
    expect(parseIsoDate('02.01.2026'), isNull);
  });

  test('parseGermanDate', () {
    expect(parseGermanDate('02.01.2026'), DateTime(2026, 1, 2));
    expect(parseGermanDate(' 2.1.2026 '), DateTime(2026, 1, 2));
    expect(parseGermanDate('31.02.2026'), isNull);
  });

  test('parseFlexibleDate accepts both', () {
    expect(parseFlexibleDate('2026-01-02'), DateTime(2026, 1, 2));
    expect(parseFlexibleDate('02.01.2026'), DateTime(2026, 1, 2));
    expect(parseFlexibleDate('Freitag'), isNull);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

```powershell
flutter test test/core
```

Erwartet: Compile-Fehler, `result.dart` und `dates.dart` fehlen.

- [ ] **Step 3: Implementieren**

`lib/core/result.dart`:

```dart
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  R when<R>({
    required R Function(T value, List<String> warnings) ok,
    required R Function(String message) err,
  }) {
    return switch (this) {
      Ok<T>(:final value, :final warnings) => ok(value, warnings),
      Err<T>(:final message) => err(message),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value, {this.warnings = const []});
  final T value;
  final List<String> warnings;
}

final class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}
```

`lib/core/dates.dart`:

```dart
extension DateOnlyX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Kalendertage von [from] bis [to], unabhängig von Sommer-/Winterzeit.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

DateTime? _buildDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final d = DateTime(year, month, day);
  if (d.month != month || d.day != day) return null; // z. B. 31.02.
  return d;
}

final _iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
final _german = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');

DateTime? parseIsoDate(String input) {
  final m = _iso.firstMatch(input.trim());
  if (m == null) return null;
  return _buildDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

DateTime? parseGermanDate(String input) {
  final m = _german.firstMatch(input.trim());
  if (m == null) return null;
  return _buildDate(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
}

DateTime? parseFlexibleDate(String input) =>
    parseIsoDate(input) ?? parseGermanDate(input);
```

`lib/core/clock.dart`:

```dart
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  const FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/core
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/core test/core
git commit -m "Add Result type, date helpers and Clock`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 3: Datenmodelle und AppData

**Files:**
- Create: `lib/data/models/pickup_event.dart`, `lib/data/models/waste_type.dart`, `lib/data/models/reminder_rule.dart`, `lib/data/models/subscription.dart`, `lib/data/models/app_data.dart`
- Test: `test/data/models_test.dart`

**Interfaces:**
- Consumes: `DateOnlyX`, `parseIsoDate` aus Task 2.
- Produces:
  - `class PickupEvent { DateTime date; String wasteTypeId; String sourceId; String? note; String get key; toJson(); factory fromJson(Map); }`
  - `class WasteType { String id; String displayName; int color; String icon; bool notificationsEnabled; copyWith(...); toJson(); fromJson(); }`
  - `class ReminderRule { String id; int daysBefore; int hour; int minute; bool enabled; copyWith(...); toJson(); fromJson(); static List<ReminderRule> defaults(); static const maxRules = 5; }`
  - `class Subscription { String url; DateTime? lastFetched; String? lastError; copyWith(...); toJson(); fromJson(); }`
  - `class AppData { List<PickupEvent> events; List<WasteType> wasteTypes; static const empty; copyWith(...); toJson(); fromJson(); static const schemaVersion = 1; }`

- [ ] **Step 1: Test schreiben**

`test/data/models_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PickupEvent key and json roundtrip', () {
    final e = PickupEvent(
      date: DateTime(2026, 1, 2),
      wasteTypeId: 'biotonne',
      sourceId: 'file:a.csv',
      note: 'bis 6:30',
    );
    expect(e.key, '2026-01-02|biotonne');
    final back = PickupEvent.fromJson(e.toJson());
    expect(back.date, DateTime(2026, 1, 2));
    expect(back.wasteTypeId, 'biotonne');
    expect(back.sourceId, 'file:a.csv');
    expect(back.note, 'bis 6:30');
    expect(back, equals(e));
  });

  test('WasteType json roundtrip and copyWith', () {
    const t = WasteType(
      id: 'biotonne',
      displayName: 'Biotonne',
      color: 0xFF6D4C41,
      icon: 'leaf',
      notificationsEnabled: true,
    );
    final back = WasteType.fromJson(t.toJson());
    expect(back.id, 'biotonne');
    expect(back.color, 0xFF6D4C41);
    expect(t.copyWith(notificationsEnabled: false).notificationsEnabled, false);
    expect(t.copyWith(displayName: 'Bio').id, 'biotonne');
  });

  test('ReminderRule defaults and json', () {
    final d = ReminderRule.defaults();
    expect(d.length, 2);
    expect(d[0].daysBefore, 1);
    expect(d[0].hour, 18);
    expect(d[0].minute, 0);
    expect(d[1].daysBefore, 0);
    expect(d[1].hour, 7);
    expect(d.every((r) => r.enabled), isTrue);
    final back = ReminderRule.fromJson(d[0].toJson());
    expect(back.id, d[0].id);
    expect(ReminderRule.maxRules, 5);
  });

  test('Subscription json roundtrip with nulls', () {
    const s = Subscription(url: 'https://x.de/a.ics');
    final back = Subscription.fromJson(s.toJson());
    expect(back.url, 'https://x.de/a.ics');
    expect(back.lastFetched, isNull);
    expect(back.lastError, isNull);
    final s2 = s.copyWith(lastFetched: DateTime(2026, 1, 1, 10), lastError: 'x');
    final back2 = Subscription.fromJson(s2.toJson());
    expect(back2.lastFetched, DateTime(2026, 1, 1, 10));
    expect(back2.lastError, 'x');
    expect(s2.copyWith(clearError: true).lastError, isNull);
  });

  test('AppData json roundtrip includes schemaVersion', () {
    final data = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 's'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Biotonne', color: 1, icon: 'leaf'),
      ],
    );
    final json = data.toJson();
    expect(json['schemaVersion'], AppData.schemaVersion);
    final back = AppData.fromJson(json);
    expect(back.events.length, 1);
    expect(back.wasteTypes.single.id, 'biotonne');
    expect(AppData.empty.events, isEmpty);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/data/models_test.dart
```

Erwartet: Compile-Fehler, Modelle fehlen.

- [ ] **Step 3: Implementieren**

`lib/data/models/pickup_event.dart`:

```dart
import '../../core/dates.dart';

class PickupEvent {
  PickupEvent({
    required DateTime date,
    required this.wasteTypeId,
    required this.sourceId,
    this.note,
  }) : date = date.dateOnly;

  final DateTime date;
  final String wasteTypeId;
  final String sourceId;
  final String? note;

  String get key => '${date.isoDate}|$wasteTypeId';

  Map<String, dynamic> toJson() => {
        'date': date.isoDate,
        'wasteTypeId': wasteTypeId,
        'sourceId': sourceId,
        'note': note,
      };

  factory PickupEvent.fromJson(Map<String, dynamic> json) => PickupEvent(
        date: parseIsoDate(json['date'] as String)!,
        wasteTypeId: json['wasteTypeId'] as String,
        sourceId: json['sourceId'] as String,
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) => other is PickupEvent && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
```

`lib/data/models/waste_type.dart`:

```dart
class WasteType {
  const WasteType({
    required this.id,
    required this.displayName,
    required this.color,
    required this.icon,
    this.notificationsEnabled = true,
  });

  final String id;
  final String displayName;
  final int color;
  final String icon;
  final bool notificationsEnabled;

  WasteType copyWith({
    String? displayName,
    int? color,
    String? icon,
    bool? notificationsEnabled,
  }) =>
      WasteType(
        id: id,
        displayName: displayName ?? this.displayName,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'color': color,
        'icon': icon,
        'notificationsEnabled': notificationsEnabled,
      };

  factory WasteType.fromJson(Map<String, dynamic> json) => WasteType(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        color: json['color'] as int,
        icon: json['icon'] as String,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      );
}
```

`lib/data/models/reminder_rule.dart`:

```dart
class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.daysBefore,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  static const maxRules = 5;

  final String id;
  final int daysBefore;
  final int hour;
  final int minute;
  final bool enabled;

  static List<ReminderRule> defaults() => const [
        ReminderRule(id: 'default-evening', daysBefore: 1, hour: 18, minute: 0),
        ReminderRule(id: 'default-morning', daysBefore: 0, hour: 7, minute: 0),
      ];

  static String newId() => 'rule-${DateTime.now().microsecondsSinceEpoch}';

  ReminderRule copyWith({int? daysBefore, int? hour, int? minute, bool? enabled}) =>
      ReminderRule(
        id: id,
        daysBefore: daysBefore ?? this.daysBefore,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'daysBefore': daysBefore,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory ReminderRule.fromJson(Map<String, dynamic> json) => ReminderRule(
        id: json['id'] as String,
        daysBefore: json['daysBefore'] as int,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: json['enabled'] as bool? ?? true,
      );
}
```

`lib/data/models/subscription.dart`:

```dart
class Subscription {
  const Subscription({required this.url, this.lastFetched, this.lastError});

  final String url;
  final DateTime? lastFetched;
  final String? lastError;

  Subscription copyWith({
    String? url,
    DateTime? lastFetched,
    String? lastError,
    bool clearError = false,
  }) =>
      Subscription(
        url: url ?? this.url,
        lastFetched: lastFetched ?? this.lastFetched,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'lastFetched': lastFetched?.toIso8601String(),
        'lastError': lastError,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        url: json['url'] as String,
        lastFetched: json['lastFetched'] == null
            ? null
            : DateTime.parse(json['lastFetched'] as String),
        lastError: json['lastError'] as String?,
      );
}
```

`lib/data/models/app_data.dart`:

```dart
import 'pickup_event.dart';
import 'waste_type.dart';

class AppData {
  const AppData({required this.events, required this.wasteTypes});

  static const schemaVersion = 1;
  static const empty = AppData(events: [], wasteTypes: []);

  final List<PickupEvent> events;
  final List<WasteType> wasteTypes;

  AppData copyWith({List<PickupEvent>? events, List<WasteType>? wasteTypes}) =>
      AppData(events: events ?? this.events, wasteTypes: wasteTypes ?? this.wasteTypes);

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'events': events.map((e) => e.toJson()).toList(),
        'wasteTypes': wasteTypes.map((t) => t.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        events: (json['events'] as List<dynamic>)
            .map((e) => PickupEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        wasteTypes: (json['wasteTypes'] as List<dynamic>)
            .map((t) => WasteType.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/data/models_test.dart
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/data/models test/data/models_test.dart
git commit -m "Add data models with JSON serialization`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Abfuhrart-Katalog (Normalisierung, Standardfarben, Icons)

**Files:**
- Create: `lib/features/waste_types/domain/waste_type_catalog.dart`
- Test: `test/features/waste_types/waste_type_catalog_test.dart`

**Interfaces:**
- Consumes: `WasteType` aus Task 3.
- Produces: `class WasteTypeCatalog { static String cleanName(String raw); static String normalizeId(String raw); static WasteType createDefault(String raw); static const List<int> palette; static const List<String> iconKeys; static const fallbackColor; static const fallbackIcon; }`

- [ ] **Step 1: Test schreiben**

`test/features/waste_types/waste_type_catalog_test.dart`:

```dart
import 'package:abfallkalender/features/waste_types/domain/waste_type_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleanName strips Abfuhr prefix and whitespace', () {
    expect(WasteTypeCatalog.cleanName('Abfuhr: Biotonne'), 'Biotonne');
    expect(WasteTypeCatalog.cleanName('  Restmüll   Tonne '), 'Restmüll Tonne');
    expect(WasteTypeCatalog.cleanName('Abfuhr:'), 'Abfuhr:');
  });

  test('normalizeId transliterates and collapses', () {
    expect(WasteTypeCatalog.normalizeId('Abfuhr: Biotonne'), 'biotonne');
    expect(WasteTypeCatalog.normalizeId('Restmüll Tonne'), 'restmuell_tonne');
    expect(WasteTypeCatalog.normalizeId('Wertstofftonne / Gelber Container'),
        'wertstofftonne_gelber_container');
    expect(WasteTypeCatalog.normalizeId('   '), 'unbekannt');
  });

  test('createDefault assigns colors and icons by keyword', () {
    expect(WasteTypeCatalog.createDefault('Biotonne').color, 0xFF6D4C41);
    expect(WasteTypeCatalog.createDefault('Biotonne').icon, 'leaf');
    expect(WasteTypeCatalog.createDefault('Restmüll Tonne').color, 0xFF455A64);
    expect(WasteTypeCatalog.createDefault('Wertstofftonne / Gelber Container').color, 0xFFF9A825);
    expect(WasteTypeCatalog.createDefault('Gelber Sack').color, 0xFFF9A825);
    expect(WasteTypeCatalog.createDefault('Altpapier Tonne').color, 0xFF1E88E5);
    expect(WasteTypeCatalog.createDefault('Problemabfallsammlung').color, 0xFFD32F2F);
    expect(WasteTypeCatalog.createDefault('Altglas').color, 0xFF2E7D32);
    expect(WasteTypeCatalog.createDefault('Sperrmüll').color, 0xFF6A1B9A);
    expect(WasteTypeCatalog.createDefault('Weihnachtsbaum').color, WasteTypeCatalog.fallbackColor);
    expect(WasteTypeCatalog.createDefault('Weihnachtsbaum').icon, WasteTypeCatalog.fallbackIcon);
  });

  test('createDefault uses cleaned display name and normalized id', () {
    final t = WasteTypeCatalog.createDefault('Abfuhr: Biotonne');
    expect(t.id, 'biotonne');
    expect(t.displayName, 'Biotonne');
    expect(t.notificationsEnabled, isTrue);
  });

  test('palette and icon keys are non-empty and icon keys cover defaults', () {
    expect(WasteTypeCatalog.palette.length, greaterThanOrEqualTo(8));
    for (final key in ['leaf', 'trash', 'recycle', 'paper', 'warning', 'bottle', 'sofa']) {
      expect(WasteTypeCatalog.iconKeys, contains(key));
    }
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/waste_types
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/waste_types/domain/waste_type_catalog.dart`:

```dart
import '../../../data/models/waste_type.dart';

class WasteTypeCatalog {
  WasteTypeCatalog._();

  static const fallbackColor = 0xFF78909C;
  static const fallbackIcon = 'trash';

  static const List<int> palette = [
    0xFF6D4C41, // Braun
    0xFF455A64, // Dunkelgrau
    0xFFF9A825, // Gelb
    0xFF1E88E5, // Blau
    0xFFD32F2F, // Rot
    0xFF2E7D32, // Grün
    0xFF6A1B9A, // Violett
    0xFF78909C, // Neutralgrau
    0xFFEF6C00, // Orange
    0xFF00897B, // Türkis
    0xFFAD1457, // Pink
    0xFF212121, // Schwarz
  ];

  static const List<String> iconKeys = [
    'leaf', 'trash', 'recycle', 'paper', 'warning', 'bottle', 'sofa', 'tree',
  ];

  static final _prefix = RegExp(r'^(abfuhr|abholung|leerung|termin)\s*:\s*', caseSensitive: false);
  static final _spaces = RegExp(r'\s+');
  static final _nonAlnum = RegExp(r'[^a-z0-9]+');
  static final _edgeUnderscores = RegExp(r'^_+|_+$');

  static const _rules = <(List<String>, int, String)>[
    (['bio'], 0xFF6D4C41, 'leaf'),
    (['rest', 'hausmuell'], 0xFF455A64, 'trash'),
    (['wertstoff', 'gelb', 'verpackung', 'plastik'], 0xFFF9A825, 'recycle'),
    (['papier', 'karton'], 0xFF1E88E5, 'paper'),
    (['problem', 'schadstoff', 'sonder'], 0xFFD32F2F, 'warning'),
    (['glas'], 0xFF2E7D32, 'bottle'),
    (['sperr'], 0xFF6A1B9A, 'sofa'),
  ];

  static String cleanName(String raw) {
    final trimmed = raw.trim();
    final stripped = trimmed.replaceFirst(_prefix, '').replaceAll(_spaces, ' ').trim();
    return stripped.isEmpty ? trimmed : stripped;
  }

  static String normalizeId(String raw) {
    var s = cleanName(raw).toLowerCase();
    s = s
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    s = s.replaceAll(_nonAlnum, '_').replaceAll(_edgeUnderscores, '');
    return s.isEmpty ? 'unbekannt' : s;
  }

  static WasteType createDefault(String raw) {
    final id = normalizeId(raw);
    var color = fallbackColor;
    var icon = fallbackIcon;
    for (final (keywords, c, i) in _rules) {
      if (keywords.any(id.contains)) {
        color = c;
        icon = i;
        break;
      }
    }
    return WasteType(id: id, displayName: cleanName(raw), color: color, icon: icon);
  }
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/waste_types
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/waste_types test/features/waste_types
git commit -m "Add waste type catalog with normalization and defaults`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 5: Text-Dekodierung (UTF-8 mit Fallback Windows-1252)

**Files:**
- Create: `lib/features/import/domain/text_decoding.dart`
- Test: `test/features/import/text_decoding_test.dart`

**Interfaces:**
- Produces: `String decodeImportBytes(List<int> bytes)` – entfernt UTF-8-BOM, dekodiert strikt UTF-8, bei Fehler Windows-1252.

- [ ] **Step 1: Test schreiben**

`test/features/import/text_decoding_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes valid utf8', () {
    expect(decodeImportBytes(utf8.encode('Restmüll')), 'Restmüll');
  });

  test('strips utf8 BOM', () {
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('Datum;Art')];
    expect(decodeImportBytes(bytes), 'Datum;Art');
  });

  test('falls back to windows-1252 for latin bytes', () {
    final bytes = [...'Restm'.codeUnits, 0xFC, ...'ll'.codeUnits];
    expect(decodeImportBytes(bytes), 'Restmüll');
  });

  test('maps windows-1252 upper range (euro sign, dashes)', () {
    expect(decodeImportBytes([0x80]), '€');
    expect(decodeImportBytes([0x96]), '–');
  });

  test('fixture csv decodes with umlauts', () {
    final bytes = File('test/fixtures/augsburg_2026.csv').readAsBytesSync();
    final text = decodeImportBytes(bytes);
    expect(text, contains('Restmüll Tonne'));
    expect(text, contains('"Wochentag";"Datum";"Abfuhrart"'));
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import/text_decoding_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/text_decoding.dart`:

```dart
import 'dart:convert';

const _cp1252High = <int, int>{
  0x80: 0x20AC, 0x82: 0x201A, 0x83: 0x0192, 0x84: 0x201E, 0x85: 0x2026,
  0x86: 0x2020, 0x87: 0x2021, 0x88: 0x02C6, 0x89: 0x2030, 0x8A: 0x0160,
  0x8B: 0x2039, 0x8C: 0x0152, 0x8E: 0x017D, 0x91: 0x2018, 0x92: 0x2019,
  0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013, 0x97: 0x2014,
  0x98: 0x02DC, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A, 0x9C: 0x0153,
  0x9E: 0x017E, 0x9F: 0x0178,
};

/// Dekodiert Importdateien: UTF-8 (mit optionalem BOM), sonst Windows-1252.
String decodeImportBytes(List<int> bytes) {
  var data = bytes;
  if (data.length >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    data = data.sublist(3);
  }
  try {
    return utf8.decode(data, allowMalformed: false);
  } on FormatException {
    return _decodeCp1252(data);
  }
}

String _decodeCp1252(List<int> bytes) {
  final units = bytes.map((b) {
    if (b >= 0x80 && b <= 0x9F) return _cp1252High[b] ?? b;
    return b;
  }).toList();
  return String.fromCharCodes(units);
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import/text_decoding_test.dart
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/import test/features/import
git commit -m "Add import text decoding with cp1252 fallback`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: ICS-Parser

**Files:**
- Create: `lib/features/import/domain/raw_pickup.dart`, `lib/features/import/domain/ics_parser.dart`
- Test: `test/features/import/ics_parser_test.dart`

**Interfaces:**
- Consumes: `Result`, `Ok`, `Err` aus Task 2.
- Produces: `class RawPickup { DateTime date; String rawName; String? note; }`; `class IcsParser { static bool looksLikeIcs(String text); Result<List<RawPickup>> parse(String text); }`

- [ ] **Step 1: Test schreiben**

`test/features/import/ics_parser_test.dart`:

```dart
import 'dart:io';

import 'package:abfallkalender/core/result.dart';
import 'package:abfallkalender/features/import/domain/ics_parser.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:flutter_test/flutter_test.dart';

List<RawPickup> okValue(Result<List<RawPickup>> r) =>
    r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

void main() {
  final parser = IcsParser();

  test('looksLikeIcs', () {
    expect(IcsParser.looksLikeIcs('BEGIN:VCALENDAR\r\nEND:VCALENDAR'), isTrue);
    expect(IcsParser.looksLikeIcs('Datum;Art'), isFalse);
  });

  test('parses fixture with 94 events', () {
    final text = File('test/fixtures/augsburg_2026.ics').readAsStringSync();
    final pickups = okValue(parser.parse(text));
    expect(pickups.length, 94);
    expect(pickups.first.date, DateTime(2026, 1, 2));
    expect(pickups.first.rawName, 'Abfuhr: Biotonne');
    expect(pickups.first.note, contains('6.30 Uhr'));
    expect(pickups.map((p) => p.rawName).toSet().length, 5);
  });

  test('unfolds continuation lines and unescapes text', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20260105T060000
SUMMARY:Abfuhr: Wertstofftonne \\/ Gel
 ber Container\\, Hof
DESCRIPTION:Zeile 1\\nZeile 2\\; Ende
END:VEVENT
END:VCALENDAR
''';
    final p = okValue(parser.parse(text)).single;
    expect(p.rawName, 'Abfuhr: Wertstofftonne / Gelber Container, Hof');
    expect(p.note, 'Zeile 1\nZeile 2; Ende');
  });

  test('handles VALUE=DATE, TZID and UTC forms', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260102
SUMMARY:A
END:VEVENT
BEGIN:VEVENT
DTSTART;TZID=Europe/Berlin:20260103T060000
SUMMARY:B
END:VEVENT
BEGIN:VEVENT
DTSTART:20260104T050000Z
SUMMARY:C
END:VEVENT
END:VCALENDAR
''';
    final ps = okValue(parser.parse(text));
    expect(ps.map((p) => p.date).toList(),
        [DateTime(2026, 1, 2), DateTime(2026, 1, 3), DateTime(2026, 1, 4)]);
  });

  test('skips events without date or summary and reports warning', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Ohne Datum
END:VEVENT
BEGIN:VEVENT
DTSTART:20260104
END:VEVENT
BEGIN:VEVENT
DTSTART:20260105
SUMMARY:Gültig
END:VEVENT
END:VCALENDAR
''';
    final r = parser.parse(text);
    final warnings = r.when(ok: (_, w) => w, err: (_) => <String>[]);
    expect(okValue(r).length, 1);
    expect(warnings.single, contains('2'));
  });

  test('returns Err when no events', () {
    final r = parser.parse('BEGIN:VCALENDAR\nEND:VCALENDAR');
    expect(r.isOk, isFalse);
    expect(r.when(ok: (_, __) => '', err: (m) => m), contains('keine Termine'));
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import/ics_parser_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/raw_pickup.dart`:

```dart
class RawPickup {
  const RawPickup({required this.date, required this.rawName, this.note});
  final DateTime date;
  final String rawName;
  final String? note;
}
```

`lib/features/import/domain/ics_parser.dart`:

```dart
import '../../../core/result.dart';
import 'raw_pickup.dart';

class IcsParser {
  static const noEventsMessage =
      'Die ICS-Datei enthält keine Termine. Erwartet werden VEVENT-Einträge mit DTSTART und SUMMARY.';

  static bool looksLikeIcs(String text) => text.contains('BEGIN:VCALENDAR');

  static final _dateStart = RegExp(r'^(\d{4})(\d{2})(\d{2})');
  static final _escape = RegExp(r'\\(.)');

  Result<List<RawPickup>> parse(String text) {
    final pickups = <RawPickup>[];
    var skipped = 0;
    var inEvent = false;
    String? dtstart;
    String? summary;
    String? description;

    for (final line in _unfold(text)) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        dtstart = null;
        summary = null;
        description = null;
        continue;
      }
      if (line == 'END:VEVENT') {
        inEvent = false;
        final date = dtstart == null ? null : _parseDate(dtstart);
        if (date == null || summary == null || summary.trim().isEmpty) {
          skipped++;
        } else {
          pickups.add(RawPickup(date: date, rawName: summary.trim(), note: description));
        }
        continue;
      }
      if (!inEvent) continue;

      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final name = line.substring(0, colon).split(';').first.toUpperCase();
      final value = line.substring(colon + 1);
      switch (name) {
        case 'DTSTART':
          dtstart = value;
        case 'SUMMARY':
          summary = _unescape(value);
        case 'DESCRIPTION':
          description = _unescape(value);
      }
    }

    if (pickups.isEmpty) return const Err(noEventsMessage);
    return Ok(
      pickups,
      warnings: skipped > 0 ? ['$skipped Einträge ohne Datum oder Titel übersprungen.'] : const [],
    );
  }

  List<String> _unfold(String text) {
    final out = <String>[];
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] = out.last + line.substring(1);
      } else {
        out.add(line);
      }
    }
    return out;
  }

  DateTime? _parseDate(String value) {
    final m = _dateStart.firstMatch(value.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, mo, d);
    if (date.month != mo || date.day != d) return null;
    return date;
  }

  String _unescape(String value) => value.replaceAllMapped(_escape, (m) {
        final c = m[1]!;
        return (c == 'n' || c == 'N') ? '\n' : c;
      });
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import/ics_parser_test.dart
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/import test/features/import
git commit -m "Add ICS parser`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: CSV-Parser

**Files:**
- Create: `lib/features/import/domain/csv_parser.dart`
- Test: `test/features/import/csv_parser_test.dart`

**Interfaces:**
- Consumes: `Result`, `parseFlexibleDate` (Task 2), `RawPickup` (Task 6).
- Produces: `class CsvParser { Result<List<RawPickup>> parse(String text); }`

- [ ] **Step 1: Test schreiben**

`test/features/import/csv_parser_test.dart`:

```dart
import 'dart:io';

import 'package:abfallkalender/core/result.dart';
import 'package:abfallkalender/features/import/domain/csv_parser.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:abfallkalender/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

List<RawPickup> okValue(Result<List<RawPickup>> r) =>
    r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

void main() {
  final parser = CsvParser();

  test('parses fixture csv (semicolon, quoted, German dates)', () {
    final text = decodeImportBytes(File('test/fixtures/augsburg_2026.csv').readAsBytesSync());
    final ps = okValue(parser.parse(text));
    expect(ps.length, 94);
    expect(ps.first.date, DateTime(2026, 1, 2));
    expect(ps.first.rawName, 'Biotonne');
    expect(ps[1].rawName, 'Restmüll Tonne');
    expect(ps.first.note, isNull);
  });

  test('parses comma separated with ISO dates and English headers, CRLF', () {
    const text = 'Date,Type\r\n2026-02-03,Paper\r\n2026-02-10,"Bio, Garden"\r\n';
    final ps = okValue(parser.parse(text));
    expect(ps.length, 2);
    expect(ps[1].rawName, 'Bio, Garden');
    expect(ps[1].date, DateTime(2026, 2, 10));
  });

  test('works without header using column heuristics', () {
    const text = 'Freitag;02.01.2026;Biotonne\nFreitag;09.01.2026;Restmüll\n';
    final ps = okValue(parser.parse(text));
    expect(ps.length, 2);
    expect(ps[1].rawName, 'Restmüll');
  });

  test('handles escaped quotes', () {
    const text = 'Datum;Art\n02.01.2026;"Tonne ""gelb"""\n';
    expect(okValue(parser.parse(text)).single.rawName, 'Tonne "gelb"');
  });

  test('skips rows with invalid dates and warns', () {
    const text = 'Datum;Art\n02.01.2026;Bio\nkein Datum;Bio\n\n03.01.2026;Rest\n';
    final r = parser.parse(text);
    expect(okValue(r).length, 2);
    expect(r.when(ok: (_, w) => w.single, err: (m) => m), contains('1'));
  });

  test('returns Err for empty and for no recognizable columns', () {
    expect(parser.parse('').isOk, isFalse);
    expect(parser.parse('a;b\nc;d\n').isOk, isFalse);
    final msg = parser.parse('a;b\nc;d\n').when(ok: (_, __) => '', err: (m) => m);
    expect(msg, contains('Datum'));
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import/csv_parser_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/csv_parser.dart`:

```dart
import '../../../core/dates.dart';
import '../../../core/result.dart';
import 'raw_pickup.dart';

class CsvParser {
  static const emptyMessage = 'Die Datei ist leer.';
  static const noDateColumnMessage =
      'Die Datei enthält keine erkennbaren Termine. Erwartet wird eine Spalte mit Datum (z. B. 02.01.2026) und eine mit der Abfuhrart.';
  static const noTypeColumnMessage =
      'Die Datei enthält keine Spalte mit der Abfuhrart neben der Datumsspalte.';

  static const _dateHeaders = {'datum', 'date', 'termin', 'tag'};
  static const _typeHeaders = {
    'abfuhrart', 'abfallart', 'art', 'typ', 'type', 'fraktion', 'tonne', 'abfall', 'kategorie',
  };
  static const _weekdays = {
    'montag', 'dienstag', 'mittwoch', 'donnerstag', 'freitag', 'samstag', 'sonntag',
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    'mo', 'di', 'mi', 'do', 'fr', 'sa', 'so',
  };

  Result<List<RawPickup>> parse(String text) {
    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const Err(emptyMessage);

    final delimiter = _detectDelimiter(lines.first);
    final rows = lines.map((l) => _splitLine(l, delimiter)).toList();

    final hasHeader = rows.first.every((c) => parseFlexibleDate(c) == null);
    final header = hasHeader ? rows.first.map((h) => h.trim().toLowerCase()).toList() : null;
    final dataRows = hasHeader ? rows.sublist(1) : rows;
    if (dataRows.isEmpty) return const Err(noDateColumnMessage);

    final dateCol = _findDateColumn(header, dataRows);
    if (dateCol == null) return const Err(noDateColumnMessage);
    final typeCol = _findTypeColumn(header, dataRows, dateCol);
    if (typeCol == null) return const Err(noTypeColumnMessage);

    final pickups = <RawPickup>[];
    var skipped = 0;
    for (final row in dataRows) {
      if (row.length <= dateCol || row.length <= typeCol) {
        skipped++;
        continue;
      }
      final date = parseFlexibleDate(row[dateCol]);
      final name = row[typeCol].trim();
      if (date == null || name.isEmpty) {
        skipped++;
        continue;
      }
      pickups.add(RawPickup(date: date, rawName: name));
    }

    if (pickups.isEmpty) return const Err(noDateColumnMessage);
    return Ok(
      pickups,
      warnings: skipped > 0 ? ['$skipped Zeilen ohne gültiges Datum oder Abfuhrart übersprungen.'] : const [],
    );
  }

  String _detectDelimiter(String line) {
    var best = ';';
    var bestCount = -1;
    for (final d in [';', ',', '\t']) {
      final count = d.allMatches(line).length;
      if (count > bestCount) {
        best = d;
        bestCount = count;
      }
    }
    return best;
  }

  List<String> _splitLine(String line, String delimiter) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
      } else if (c == delimiter) {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    fields.add(buf.toString());
    return fields.map((f) => f.trim()).toList();
  }

  int _columnCount(List<List<String>> rows) =>
      rows.fold(0, (max, r) => r.length > max ? r.length : max);

  bool _majority(List<List<String>> rows, int col, bool Function(String) test) {
    var hits = 0;
    var total = 0;
    for (final r in rows) {
      if (r.length <= col) continue;
      total++;
      if (test(r[col])) hits++;
    }
    return total > 0 && hits * 2 >= total;
  }

  int? _findDateColumn(List<String>? header, List<List<String>> rows) {
    if (header != null) {
      final idx = header.indexWhere(_dateHeaders.contains);
      if (idx >= 0 && _majority(rows, idx, (v) => parseFlexibleDate(v) != null)) return idx;
    }
    for (var c = 0; c < _columnCount(rows); c++) {
      if (_majority(rows, c, (v) => parseFlexibleDate(v) != null)) return c;
    }
    return null;
  }

  int? _findTypeColumn(List<String>? header, List<List<String>> rows, int dateCol) {
    bool isTypeValue(String v) {
      final t = v.trim();
      return t.isNotEmpty &&
          parseFlexibleDate(t) == null &&
          !_weekdays.contains(t.toLowerCase().replaceAll('.', ''));
    }

    if (header != null) {
      final idx = header.indexWhere(_typeHeaders.contains);
      if (idx >= 0 && idx != dateCol) return idx;
    }
    for (var c = 0; c < _columnCount(rows); c++) {
      if (c == dateCol) continue;
      if (_majority(rows, c, isTypeValue)) return c;
    }
    return null;
  }
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import/csv_parser_test.dart
```

Erwartet: `All tests passed!`. Falls der Test „no recognizable columns" fehlschlägt, weil `a;b / c;d` eine Typspalte ohne Datumsspalte hat: Der Datumscheck kommt zuerst und liefert `noDateColumnMessage`, das enthält „Datum".

- [ ] **Step 5: Commit**

```powershell
git add lib/features/import test/features/import
git commit -m "Add CSV parser with delimiter and column detection`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 8: ImportService und Merge-Logik

**Files:**
- Create: `lib/features/import/domain/parsed_import.dart`, `lib/features/import/domain/import_service.dart`, `lib/features/import/domain/apply_import.dart`
- Test: `test/features/import/import_service_test.dart`, `test/features/import/apply_import_test.dart`

**Interfaces:**
- Consumes: `IcsParser`, `CsvParser`, `decodeImportBytes`, `RawPickup`, `AppData`, `PickupEvent`, `WasteType`, `WasteTypeCatalog`.
- Produces:
  - `class ParsedImport { String sourceId; List<RawPickup> pickups; List<String> warnings; DateTime get firstDate; DateTime get lastDate; List<String> get distinctRawNames; }`
  - `class ImportService { ImportService({IcsParser? ics, CsvParser? csv}); Result<ParsedImport> parseBytes({required List<int> bytes, required String sourceId}); Result<ParsedImport> parseText({required String text, required String sourceId}); }`
  - `enum ImportMode { merge, replace }`
  - `class ImportOutcome { AppData data; int imported; List<WasteType> newWasteTypes; }`
  - `ImportOutcome applyImport({required AppData current, required ParsedImport parsed, required ImportMode mode})`

- [ ] **Step 1: Tests schreiben**

`test/features/import/import_service_test.dart`:

```dart
import 'dart:io';

import 'package:abfallkalender/features/import/domain/import_service.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ImportService();

  ParsedImport ok(r) => r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

  test('detects ics by content and parses fixture', () {
    final bytes = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();
    final p = ok(service.parseBytes(bytes: bytes, sourceId: 'file:a.ics'));
    expect(p.pickups.length, 94);
    expect(p.sourceId, 'file:a.ics');
    expect(p.firstDate, DateTime(2026, 1, 2));
    expect(p.lastDate.year, 2026);
    expect(p.distinctRawNames.length, 5);
  });

  test('detects csv by content (cp1252) and parses fixture', () {
    final bytes = File('test/fixtures/augsburg_2026.csv').readAsBytesSync();
    final p = ok(service.parseBytes(bytes: bytes, sourceId: 'file:a.csv'));
    expect(p.pickups.length, 94);
    expect(p.distinctRawNames, contains('Restmüll Tonne'));
  });

  test('returns Err for html content', () {
    final r = service.parseText(text: '<html><body>404</body></html>', sourceId: 'url:x');
    expect(r.isOk, isFalse);
  });
}
```

`test/features/import/apply_import_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/import/domain/apply_import.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedImport parsed(String source, List<RawPickup> pickups) =>
    ParsedImport(sourceId: source, pickups: pickups, warnings: const []);

void main() {
  test('creates waste types with defaults and dedupes duplicate rows', () {
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Abfuhr: Biotonne'),
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne'),
      RawPickup(date: DateTime(2026, 1, 9), rawName: 'Restmüll Tonne'),
    ]);
    final out = applyImport(current: AppData.empty, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.length, 2);
    expect(out.imported, 2);
    expect(out.data.wasteTypes.map((t) => t.id), containsAll(['biotonne', 'restmuell_tonne']));
    expect(out.newWasteTypes.length, 2);
    expect(out.data.wasteTypes.firstWhere((t) => t.id == 'biotonne').color, 0xFF6D4C41);
  });

  test('merge keeps other sources, replaces same source (handles removals)', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'file:a'),
        PickupEvent(date: DateTime(2026, 1, 3), wasteTypeId: 'biotonne', sourceId: 'file:a'),
        PickupEvent(date: DateTime(2026, 2, 1), wasteTypeId: 'papier', sourceId: 'url:x'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Meine Bio', color: 1, icon: 'leaf'),
        WasteType(id: 'papier', displayName: 'Papier', color: 2, icon: 'paper'),
      ],
    );
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne'),
      RawPickup(date: DateTime(2026, 1, 10), rawName: 'Biotonne'),
    ]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.merge);
    final keys = out.data.events.map((e) => e.key).toList();
    expect(keys, containsAll(['2026-01-02|biotonne', '2026-01-10|biotonne', '2026-02-01|papier']));
    expect(keys, isNot(contains('2026-01-03|biotonne')));
    expect(out.data.events.length, 3);
    // user customisations survive
    expect(out.data.wasteTypes.firstWhere((t) => t.id == 'biotonne').displayName, 'Meine Bio');
    expect(out.newWasteTypes, isEmpty);
  });

  test('existing event with same key from another source wins', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'url:x', note: 'alt'),
      ],
      wasteTypes: const [WasteType(id: 'biotonne', displayName: 'Bio', color: 1, icon: 'leaf')],
    );
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne', note: 'neu'),
    ]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.single.note, 'alt');
  });

  test('replace drops all events but keeps waste types', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 2, 1), wasteTypeId: 'papier', sourceId: 'url:x'),
      ],
      wasteTypes: const [WasteType(id: 'papier', displayName: 'Papier', color: 2, icon: 'paper')],
    );
    final p = parsed('file:a', [RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne')]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.replace);
    expect(out.data.events.single.wasteTypeId, 'biotonne');
    expect(out.data.wasteTypes.map((t) => t.id), containsAll(['papier', 'biotonne']));
  });

  test('events are sorted by date', () {
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 3, 1), rawName: 'A'),
      RawPickup(date: DateTime(2026, 1, 1), rawName: 'B'),
    ]);
    final out = applyImport(current: AppData.empty, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.first.date, DateTime(2026, 1, 1));
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/parsed_import.dart`:

```dart
import 'raw_pickup.dart';

class ParsedImport {
  const ParsedImport({required this.sourceId, required this.pickups, required this.warnings});

  final String sourceId;
  final List<RawPickup> pickups;
  final List<String> warnings;

  DateTime get firstDate =>
      pickups.map((p) => p.date).reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get lastDate =>
      pickups.map((p) => p.date).reduce((a, b) => a.isAfter(b) ? a : b);

  List<String> get distinctRawNames {
    final seen = <String>{};
    return [for (final p in pickups) if (seen.add(p.rawName)) p.rawName];
  }
}
```

`lib/features/import/domain/import_service.dart`:

```dart
import '../../../core/result.dart';
import 'csv_parser.dart';
import 'ics_parser.dart';
import 'parsed_import.dart';
import 'text_decoding.dart';

class ImportService {
  ImportService({IcsParser? ics, CsvParser? csv})
      : _ics = ics ?? IcsParser(),
        _csv = csv ?? CsvParser();

  final IcsParser _ics;
  final CsvParser _csv;

  Result<ParsedImport> parseBytes({required List<int> bytes, required String sourceId}) =>
      parseText(text: decodeImportBytes(bytes), sourceId: sourceId);

  Result<ParsedImport> parseText({required String text, required String sourceId}) {
    final result = IcsParser.looksLikeIcs(text) ? _ics.parse(text) : _csv.parse(text);
    return result.when(
      ok: (pickups, warnings) => Ok(
        ParsedImport(sourceId: sourceId, pickups: pickups, warnings: warnings),
        warnings: warnings,
      ),
      err: (message) => Err(message),
    );
  }
}
```

`lib/features/import/domain/apply_import.dart`:

```dart
import '../../../data/models/app_data.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/waste_type.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import 'parsed_import.dart';

enum ImportMode { merge, replace }

class ImportOutcome {
  const ImportOutcome({required this.data, required this.imported, required this.newWasteTypes});
  final AppData data;
  final int imported;
  final List<WasteType> newWasteTypes;
}

ImportOutcome applyImport({
  required AppData current,
  required ParsedImport parsed,
  required ImportMode mode,
}) {
  final types = {for (final t in current.wasteTypes) t.id: t};
  final newTypes = <WasteType>[];

  final incoming = <String, PickupEvent>{};
  for (final p in parsed.pickups) {
    final id = WasteTypeCatalog.normalizeId(p.rawName);
    if (!types.containsKey(id)) {
      final created = WasteTypeCatalog.createDefault(p.rawName);
      types[id] = created;
      newTypes.add(created);
    }
    final event = PickupEvent(
      date: p.date,
      wasteTypeId: id,
      sourceId: parsed.sourceId,
      note: p.note,
    );
    incoming.putIfAbsent(event.key, () => event);
  }

  final base = mode == ImportMode.replace
      ? <PickupEvent>[]
      : current.events.where((e) => e.sourceId != parsed.sourceId).toList();
  final existingKeys = base.map((e) => e.key).toSet();
  final added = incoming.values.where((e) => !existingKeys.contains(e.key));

  final events = [...base, ...added]..sort((a, b) => a.date.compareTo(b.date));
  return ImportOutcome(
    data: AppData(events: events, wasteTypes: types.values.toList()),
    imported: incoming.length,
    newWasteTypes: newTypes,
  );
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/import test/features/import
git commit -m "Add import service and merge logic`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Repositories (JSON-Datei, SharedPreferences) und In-Memory-Fakes

**Files:**
- Create: `lib/data/repositories/event_repository.dart`, `lib/data/repositories/json_file_event_repository.dart`, `lib/data/repositories/settings_repository.dart`, `lib/data/repositories/prefs_settings_repository.dart`
- Create: `test/support/in_memory_repositories.dart`
- Test: `test/data/json_file_event_repository_test.dart`, `test/data/prefs_settings_repository_test.dart`

**Interfaces:**
- Consumes: `AppData`, `ReminderRule`, `Subscription`.
- Produces:
  - `class LoadResult { AppData data; bool wasCorrupt; }`
  - `abstract class EventRepository { Future<LoadResult> load(); Future<void> save(AppData data); }`
  - `class JsonFileEventRepository implements EventRepository { JsonFileEventRepository(Directory directory); }`
  - `abstract class SettingsRepository { Future<List<ReminderRule>?> loadRules(); Future<void> saveRules(List<ReminderRule>); Future<Subscription?> loadSubscription(); Future<void> saveSubscription(Subscription?); Future<DateTime?> loadLastScheduleRun(); Future<void> saveLastScheduleRun(DateTime); }`
  - `class PrefsSettingsRepository implements SettingsRepository { PrefsSettingsRepository(SharedPreferences prefs); }`
  - Test-Fakes: `InMemoryEventRepository` (mit Feldern `AppData data`, `bool corruptOnLoad`, `int saveCount`), `InMemorySettingsRepository` (Felder `rules`, `subscription`, `lastScheduleRun`).

- [ ] **Step 1: Tests schreiben**

`test/data/json_file_event_repository_test.dart`:

```dart
import 'dart:io';

import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/data/repositories/json_file_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('abfall_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('load on missing file returns empty, not corrupt', () async {
    final repo = JsonFileEventRepository(dir);
    final r = await repo.load();
    expect(r.data.events, isEmpty);
    expect(r.wasCorrupt, isFalse);
  });

  test('save then load roundtrips and leaves no temp file', () async {
    final repo = JsonFileEventRepository(dir);
    await repo.save(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
    ));
    final r = await repo.load();
    expect(r.data.events.single.key, '2026-01-02|b');
    expect(File('${dir.path}/data.json').existsSync(), isTrue);
    expect(File('${dir.path}/data.json.tmp').existsSync(), isFalse);
  });

  test('corrupt file is backed up and empty data returned', () async {
    File('${dir.path}/data.json').writeAsStringSync('{not json');
    final repo = JsonFileEventRepository(dir);
    final r = await repo.load();
    expect(r.wasCorrupt, isTrue);
    expect(r.data.events, isEmpty);
    expect(File('${dir.path}/data.json.broken').existsSync(), isTrue);
    expect(File('${dir.path}/data.json').existsSync(), isFalse);
  });

  test('save overwrites existing file', () async {
    final repo = JsonFileEventRepository(dir);
    await repo.save(AppData.empty);
    await repo.save(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [],
    ));
    expect((await repo.load()).data.events.length, 1);
  });
}
```

`test/data/prefs_settings_repository_test.dart`:

```dart
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/repositories/prefs_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rules: null when never saved, roundtrip after save', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadRules(), isNull);
    await repo.saveRules(ReminderRule.defaults());
    final rules = await repo.loadRules();
    expect(rules!.length, 2);
    expect(rules[0].id, 'default-evening');
  });

  test('subscription roundtrip and clearing', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadSubscription(), isNull);
    await repo.saveSubscription(const Subscription(url: 'https://a.de/x.ics'));
    expect((await repo.loadSubscription())!.url, 'https://a.de/x.ics');
    await repo.saveSubscription(null);
    expect(await repo.loadSubscription(), isNull);
  });

  test('last schedule run roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadLastScheduleRun(), isNull);
    await repo.saveLastScheduleRun(DateTime(2026, 1, 1, 8));
    expect(await repo.loadLastScheduleRun(), DateTime(2026, 1, 1, 8));
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/data
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/data/repositories/event_repository.dart`:

```dart
import '../models/app_data.dart';

class LoadResult {
  const LoadResult({required this.data, required this.wasCorrupt});
  final AppData data;
  final bool wasCorrupt;
}

abstract class EventRepository {
  Future<LoadResult> load();
  Future<void> save(AppData data);
}
```

`lib/data/repositories/json_file_event_repository.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import '../models/app_data.dart';
import 'event_repository.dart';

class JsonFileEventRepository implements EventRepository {
  JsonFileEventRepository(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}data.json');

  @override
  Future<LoadResult> load() async {
    final file = _file;
    if (!await file.exists()) {
      return const LoadResult(data: AppData.empty, wasCorrupt: false);
    }
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LoadResult(data: AppData.fromJson(json), wasCorrupt: false);
    } catch (_) {
      final broken = File('${file.path}.broken');
      if (await broken.exists()) await broken.delete();
      await file.rename(broken.path);
      return const LoadResult(data: AppData.empty, wasCorrupt: true);
    }
  }

  @override
  Future<void> save(AppData data) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(_file.path);
  }
}
```

`lib/data/repositories/settings_repository.dart`:

```dart
import '../models/reminder_rule.dart';
import '../models/subscription.dart';

abstract class SettingsRepository {
  /// `null` bedeutet: noch nie gespeichert (Aufrufer nutzt Standardregeln).
  Future<List<ReminderRule>?> loadRules();
  Future<void> saveRules(List<ReminderRule> rules);

  Future<Subscription?> loadSubscription();
  Future<void> saveSubscription(Subscription? subscription);

  Future<DateTime?> loadLastScheduleRun();
  Future<void> saveLastScheduleRun(DateTime when);
}
```

`lib/data/repositories/prefs_settings_repository.dart`:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_rule.dart';
import '../models/subscription.dart';
import 'settings_repository.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _rulesKey = 'reminder_rules';
  static const _subscriptionKey = 'subscription';
  static const _lastRunKey = 'last_schedule_run';

  @override
  Future<List<ReminderRule>?> loadRules() async {
    final raw = _prefs.getString(_rulesKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ReminderRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveRules(List<ReminderRule> rules) =>
      _prefs.setString(_rulesKey, jsonEncode(rules.map((r) => r.toJson()).toList()));

  @override
  Future<Subscription?> loadSubscription() async {
    final raw = _prefs.getString(_subscriptionKey);
    if (raw == null) return null;
    return Subscription.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveSubscription(Subscription? subscription) async {
    if (subscription == null) {
      await _prefs.remove(_subscriptionKey);
    } else {
      await _prefs.setString(_subscriptionKey, jsonEncode(subscription.toJson()));
    }
  }

  @override
  Future<DateTime?> loadLastScheduleRun() async {
    final raw = _prefs.getString(_lastRunKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  @override
  Future<void> saveLastScheduleRun(DateTime when) =>
      _prefs.setString(_lastRunKey, when.toIso8601String());
}
```

`test/support/in_memory_repositories.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/repositories/event_repository.dart';
import 'package:abfallkalender/data/repositories/settings_repository.dart';

class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository([this.data = AppData.empty]);

  AppData data;
  bool corruptOnLoad = false;
  int saveCount = 0;

  @override
  Future<LoadResult> load() async {
    final corrupt = corruptOnLoad;
    corruptOnLoad = false;
    return LoadResult(data: corrupt ? AppData.empty : data, wasCorrupt: corrupt);
  }

  @override
  Future<void> save(AppData data) async {
    this.data = data;
    saveCount++;
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  List<ReminderRule>? rules;
  Subscription? subscription;
  DateTime? lastScheduleRun;

  @override
  Future<List<ReminderRule>?> loadRules() async => rules;
  @override
  Future<void> saveRules(List<ReminderRule> rules) async => this.rules = rules;
  @override
  Future<Subscription?> loadSubscription() async => subscription;
  @override
  Future<void> saveSubscription(Subscription? subscription) async =>
      this.subscription = subscription;
  @override
  Future<DateTime?> loadLastScheduleRun() async => lastScheduleRun;
  @override
  Future<void> saveLastScheduleRun(DateTime when) async => lastScheduleRun = when;
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/data
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories test/data test/support
git commit -m "Add JSON file and SharedPreferences repositories`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: ReminderScheduler (reines Dart)

**Files:**
- Create: `lib/features/reminders/domain/planned_notification.dart`, `lib/features/reminders/domain/reminder_scheduler.dart`
- Test: `test/features/reminders/reminder_scheduler_test.dart`

**Interfaces:**
- Consumes: `PickupEvent`, `WasteType`, `ReminderRule`, `DateOnlyX`, `parseIsoDate`.
- Produces:
  - `class PlannedNotification { int id; DateTime at; String title; String body; }`
  - `class ReminderScheduler { List<PlannedNotification> plan({required List<PickupEvent> events, required List<WasteType> wasteTypes, required List<ReminderRule> rules, required DateTime now, required int limit}); static int notificationId(DateTime date, int daysBefore, int hour, int minute); static String titleFor(int daysBefore); static String joinNames(List<String> names); }`

- [ ] **Step 1: Test schreiben**

`test/features/reminders/reminder_scheduler_test.dart`:

```dart
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier Tonne', color: 2, icon: 'paper');
const rest = WasteType(id: 'rest', displayName: 'Restmüll', color: 3, icon: 'trash', notificationsEnabled: false);

PickupEvent ev(DateTime d, String type) => PickupEvent(date: d, wasteTypeId: type, sourceId: 's');

void main() {
  final scheduler = ReminderScheduler();
  final rules = ReminderRule.defaults(); // Vortag 18:00, Abholtag 07:00
  final now = DateTime(2026, 1, 1, 12);

  test('plans one notification per day and rule, in time order', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 5), 'bio')],
      wasteTypes: const [bio],
      rules: rules,
      now: now,
      limit: 100,
    );
    expect(out.length, 2);
    expect(out[0].at, DateTime(2026, 1, 4, 18, 0));
    expect(out[0].title, 'Morgen Abholung');
    expect(out[0].body, 'Biotonne');
    expect(out[1].at, DateTime(2026, 1, 5, 7, 0));
    expect(out[1].title, 'Heute Abholung');
  });

  test('combines multiple types on one day into one notification', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 5), 'papier'), ev(DateTime(2026, 1, 5), 'bio')],
      wasteTypes: const [bio, papier],
      rules: [rules[0]],
      now: now,
      limit: 100,
    );
    expect(out.single.body, 'Altpapier Tonne und Biotonne');
  });

  test('joinNames for three uses comma and und', () {
    expect(ReminderScheduler.joinNames(['A', 'B', 'C']), 'A, B und C');
    expect(ReminderScheduler.joinNames(['A']), 'A');
  });

  test('skips muted types, disabled rules and past times', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 1), 'bio'), ev(DateTime(2026, 1, 5), 'rest')],
      wasteTypes: const [bio, rest],
      rules: [rules[0], rules[1].copyWith(enabled: false)],
      now: now,
      limit: 100,
    );
    expect(out, isEmpty);
  });

  test('respects limit and keeps earliest', () {
    final events = [for (var d = 2; d <= 30; d++) ev(DateTime(2026, 1, d), 'bio')];
    final out = scheduler.plan(
      events: events, wasteTypes: const [bio], rules: rules, now: now, limit: 5,
    );
    expect(out.length, 5);
    expect(out.first.at, DateTime(2026, 1, 1, 18));
  });

  test('titles for daysBefore', () {
    expect(ReminderScheduler.titleFor(0), 'Heute Abholung');
    expect(ReminderScheduler.titleFor(1), 'Morgen Abholung');
    expect(ReminderScheduler.titleFor(2), 'Übermorgen Abholung');
  });

  test('ids are deterministic, distinct per rule time, and positive 31-bit', () {
    final a = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 18, 0);
    final b = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 18, 0);
    final c = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 19, 0);
    final d = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 0, 18, 0);
    expect(a, b);
    expect(a, isNot(c));
    expect(a, isNot(d));
    expect(a, greaterThan(1));
    expect(a, lessThan(1 << 31));
  });

  test('rule time on DST switch day yields a valid future time', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 3, 30), 'bio')],
      wasteTypes: const [bio],
      rules: const [ReminderRule(id: 'x', daysBefore: 1, hour: 2, minute: 30)],
      now: DateTime(2026, 3, 1),
      limit: 10,
    );
    expect(out.single.at.year, 2026);
    expect(out.single.at.month, 3);
    expect(out.single.at.day, 29);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/reminders
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/reminders/domain/planned_notification.dart`:

```dart
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
}
```

`lib/features/reminders/domain/reminder_scheduler.dart`:

```dart
import '../../../core/dates.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../data/models/waste_type.dart';
import 'planned_notification.dart';

class ReminderScheduler {
  static const titleToday = 'Heute Abholung';
  static const titleTomorrow = 'Morgen Abholung';
  static const titleDayAfter = 'Übermorgen Abholung';

  static String titleFor(int daysBefore) => switch (daysBefore) {
        0 => titleToday,
        1 => titleTomorrow,
        2 => titleDayAfter,
        _ => 'Abholung in $daysBefore Tagen',
      };

  static String joinNames(List<String> names) {
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} und ${names.last}';
  }

  /// Deterministische ID: Tage seit 2000-01-01 (16 Bit) * 16384 + Slot (14 Bit) + 1000.
  /// IDs unter 1000 bleiben für feste Benachrichtigungen (Test, Hinweis) frei.
  static int notificationId(DateTime date, int daysBefore, int hour, int minute) {
    final days = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2000, 1, 1))
        .inDays;
    final slot = daysBefore * 1440 + hour * 60 + minute;
    return days * 16384 + slot + 1000;
  }

  List<PlannedNotification> plan({
    required List<PickupEvent> events,
    required List<WasteType> wasteTypes,
    required List<ReminderRule> rules,
    required DateTime now,
    required int limit,
  }) {
    final typeById = {for (final t in wasteTypes) t.id: t};
    final namesByDate = <String, Set<String>>{};
    for (final e in events) {
      final type = typeById[e.wasteTypeId];
      if (type == null || !type.notificationsEnabled) continue;
      namesByDate.putIfAbsent(e.date.isoDate, () => <String>{}).add(type.displayName);
    }

    final out = <PlannedNotification>[];
    for (final entry in namesByDate.entries) {
      final date = parseIsoDate(entry.key)!;
      final names = entry.value.toList()..sort();
      for (final rule in rules.where((r) => r.enabled)) {
        final at = DateTime(
          date.year, date.month, date.day - rule.daysBefore, rule.hour, rule.minute,
        );
        if (!at.isAfter(now)) continue;
        out.add(PlannedNotification(
          id: notificationId(date, rule.daysBefore, rule.hour, rule.minute),
          at: at,
          title: titleFor(rule.daysBefore),
          body: joinNames(names),
        ));
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out.length > limit ? out.sublist(0, limit) : out;
  }
}
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/reminders
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/reminders test/features/reminders
git commit -m "Add pure Dart reminder scheduler`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 11: NotificationGateway, Plattform-Implementierung, ReminderCoordinator, Plattformkonfiguration

**Files:**
- Create: `lib/features/reminders/domain/notification_gateway.dart`, `lib/features/reminders/domain/reminder_coordinator.dart`, `lib/features/reminders/data/local_notifications_gateway.dart`
- Create: `test/support/fake_notification_gateway.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `ios/Runner/AppDelegate.swift`
- Test: `test/features/reminders/reminder_coordinator_test.dart`

**Interfaces:**
- Consumes: `PlannedNotification`, `ReminderScheduler`, `Clock`, Modelle.
- Produces:
  - `enum NotificationPermission { granted, denied, unknown }`
  - `abstract class NotificationGateway { Future<void> initialize(); Future<bool> requestPermission(); Future<NotificationPermission> permissionStatus(); Future<bool> canScheduleExact(); Future<void> cancelAll(); Future<void> schedule(List<PlannedNotification> items); Future<void> showNow({required String title, required String body}); }`
  - `class LocalNotificationsGateway implements NotificationGateway`
  - `class ReminderCoordinator { ReminderCoordinator({required NotificationGateway gateway, required ReminderScheduler scheduler, required Clock clock, required int maxPending, required bool addRefreshHint}); static const refreshHintId = 1; static const testNotificationId = 2; Future<int> reschedule({required List<PickupEvent> events, required List<WasteType> wasteTypes, required List<ReminderRule> rules}); }`
  - `class FakeNotificationGateway implements NotificationGateway { List<PlannedNotification> scheduled; int cancelAllCount; NotificationPermission permission; bool exactAllowed; List<(String, String)> shown; }`

- [ ] **Step 1: Tests schreiben**

`test/support/fake_notification_gateway.dart`:

```dart
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/reminders/domain/planned_notification.dart';

class FakeNotificationGateway implements NotificationGateway {
  final List<PlannedNotification> scheduled = [];
  final List<(String, String)> shown = [];
  int cancelAllCount = 0;
  int requestCount = 0;
  NotificationPermission permission = NotificationPermission.unknown;
  bool exactAllowed = true;
  bool grantOnRequest = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    permission = grantOnRequest ? NotificationPermission.granted : NotificationPermission.denied;
    return grantOnRequest;
  }

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(List<PlannedNotification> items) async => scheduled.addAll(items);

  @override
  Future<void> showNow({required String title, required String body}) async =>
      shown.add((title, body));
}
```

`test/features/reminders/reminder_coordinator_test.dart`:

```dart
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_coordinator.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
PickupEvent ev(int day) =>
    PickupEvent(date: DateTime(2026, 1, day), wasteTypeId: 'bio', sourceId: 's');

void main() {
  final rules = ReminderRule.defaults();
  final clock = FixedClock(DateTime(2026, 1, 1));

  test('cancels all, schedules window, no hint when everything fits', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 60, addRefreshHint: true,
    );
    final n = await c.reschedule(events: [ev(5), ev(12)], wasteTypes: const [bio], rules: rules);
    expect(n, 4);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled.length, 4);
    expect(gateway.scheduled.any((p) => p.id == ReminderCoordinator.refreshHintId), isFalse);
  });

  test('adds refresh hint one day after last planned when truncated (iOS)', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 4, addRefreshHint: true,
    );
    final events = [for (var d = 2; d <= 20; d++) ev(d)];
    final n = await c.reschedule(events: events, wasteTypes: const [bio], rules: rules);
    expect(n, 4);
    expect(gateway.scheduled.length, 5);
    final hint = gateway.scheduled.last;
    expect(hint.id, ReminderCoordinator.refreshHintId);
    final lastReminder = gateway.scheduled[3].at;
    expect(hint.at, lastReminder.add(const Duration(days: 1)));
    expect(hint.body, contains('öffnen'));
  });

  test('no hint on android even when truncated', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 4, addRefreshHint: false,
    );
    final events = [for (var d = 2; d <= 20; d++) ev(d)];
    await c.reschedule(events: events, wasteTypes: const [bio], rules: rules);
    expect(gateway.scheduled.length, 4);
  });

  test('empty data cancels and schedules nothing', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 60, addRefreshHint: true,
    );
    final n = await c.reschedule(events: const [], wasteTypes: const [], rules: rules);
    expect(n, 0);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled, isEmpty);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/reminders/reminder_coordinator_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Interface und Coordinator implementieren**

`lib/features/reminders/domain/notification_gateway.dart`:

```dart
import 'planned_notification.dart';

enum NotificationPermission { granted, denied, unknown }

abstract class NotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<NotificationPermission> permissionStatus();
  Future<bool> canScheduleExact();
  Future<void> cancelAll();
  Future<void> schedule(List<PlannedNotification> items);
  Future<void> showNow({required String title, required String body});
}
```

`lib/features/reminders/domain/reminder_coordinator.dart`:

```dart
import '../../../core/clock.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../data/models/waste_type.dart';
import 'notification_gateway.dart';
import 'planned_notification.dart';
import 'reminder_scheduler.dart';

class ReminderCoordinator {
  ReminderCoordinator({
    required this.gateway,
    required this.scheduler,
    required this.clock,
    required this.maxPending,
    required this.addRefreshHint,
  });

  static const refreshHintId = 1;
  static const testNotificationId = 2;
  static const iosMaxPending = 60;
  static const androidMaxPending = 200;
  static const refreshHintTitle = 'Abfallkalender';
  static const refreshHintBody =
      'Bitte die App öffnen, damit die Erinnerungen aktuell bleiben.';

  final NotificationGateway gateway;
  final ReminderScheduler scheduler;
  final Clock clock;
  final int maxPending;
  final bool addRefreshHint;

  /// Plant das rollierende Fenster neu. Gibt die Anzahl geplanter Erinnerungen zurück.
  Future<int> reschedule({
    required List<PickupEvent> events,
    required List<WasteType> wasteTypes,
    required List<ReminderRule> rules,
  }) async {
    final planned = scheduler.plan(
      events: events,
      wasteTypes: wasteTypes,
      rules: rules,
      now: clock.now(),
      limit: maxPending + 1,
    );
    final truncated = planned.length > maxPending;
    final window = truncated ? planned.sublist(0, maxPending) : planned;

    await gateway.cancelAll();
    final toSchedule = [...window];
    if (addRefreshHint && truncated) {
      toSchedule.add(PlannedNotification(
        id: refreshHintId,
        at: window.last.at.add(const Duration(days: 1)),
        title: refreshHintTitle,
        body: refreshHintBody,
      ));
    }
    await gateway.schedule(toSchedule);
    return window.length;
  }
}
```

- [ ] **Step 4: Coordinator-Tests laufen lassen**

```powershell
flutter test test/features/reminders/reminder_coordinator_test.dart
```

Erwartet: `All tests passed!`

- [ ] **Step 5: Plattform-Gateway implementieren**

`lib/features/reminders/data/local_notifications_gateway.dart`:

```dart
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_gateway.dart';
import '../domain/planned_notification.dart';

class LocalNotificationsGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _android = AndroidNotificationDetails(
    'abfuhr_erinnerungen',
    'Abfuhr-Erinnerungen',
    channelDescription: 'Erinnerungen an bevorstehende Abholungen',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _android,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _androidPlugin;
      final granted = await android?.requestNotificationsPermission() ?? false;
      final exact = await android?.canScheduleExactNotifications() ?? true;
      if (!exact) await android?.requestExactAlarmsPermission();
      return granted;
    }
    if (Platform.isIOS) {
      return await _iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    if (Platform.isAndroid) {
      final enabled = await _androidPlugin?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermission.unknown;
      return enabled ? NotificationPermission.granted : NotificationPermission.denied;
    }
    if (Platform.isIOS) {
      final options = await _iosPlugin?.checkPermissions();
      if (options == null) return NotificationPermission.unknown;
      return options.isEnabled ? NotificationPermission.granted : NotificationPermission.denied;
    }
    return NotificationPermission.unknown;
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(List<PlannedNotification> items) async {
    final exact = await canScheduleExact();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final n in items) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: n.title,
        body: n.body,
      );
    }
  }

  @override
  Future<void> showNow({required String title, required String body}) =>
      _plugin.show(id: 2, title: title, body: body, notificationDetails: _details);
}
```

- [ ] **Step 6: Android konfigurieren**

`android/app/src/main/AndroidManifest.xml`: innerhalb `<manifest>` vor `<application>` ergänzen:

```xml
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.INTERNET"/>
```

Innerhalb `<application>` nach dem `<activity>`-Block ergänzen:

```xml
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

Das `android:label` der Anwendung auf `Abfallkalender` setzen.

`android/app/build.gradle.kts`: im `android { ... }`-Block `compileOptions` und `defaultConfig` anpassen, Dependency ergänzen:

```kotlin
android {
    // ... bestehende Zeilen (namespace, compileSdk, ndkVersion) bleiben

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "de.abfallkalender.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    // ... buildTypes bleibt
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

Falls `kotlinOptions` im Template bereits als `kotlin { compilerOptions { jvmTarget = ... } }` steht, dort `JvmTarget.JVM_17` setzen statt den Block zu duplizieren.

- [ ] **Step 7: iOS konfigurieren**

`ios/Runner/AppDelegate.swift`: in `application(_:didFinishLaunchingWithOptions:)` vor `GeneratedPluginRegistrant.register(with: self)` einfügen:

```swift
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
```

`ios/Runner/Info.plist`: `CFBundleDisplayName` auf `Abfallkalender` setzen (Key hinzufügen, falls nicht vorhanden):

```xml
	<key>CFBundleDisplayName</key>
	<string>Abfallkalender</string>
```

- [ ] **Step 8: Analyse und Android-Build prüfen**

```powershell
flutter analyze
flutter build apk --debug
```

Erwartet: `No issues found!` und `Built build\app\outputs\flutter-apk\app-debug.apk`. Bei Gradle-Fehler „desugar": Dependency-Block prüfen. Bei „Java version" Fehler: `flutter config --jdk-dir` aus Task 1 prüfen.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/reminders test/features/reminders test/support android ios
git commit -m "Add notification gateway, coordinator and platform setup`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 12: Riverpod-Provider: Infrastruktur, AppData, Erinnerungsregeln, ReminderSync

**Files:**
- Create: `lib/app/infrastructure_providers.dart`, `lib/features/upcoming/providers/app_data_provider.dart`, `lib/features/reminders/providers/reminder_rules_provider.dart`, `lib/features/reminders/providers/reminder_sync.dart`
- Create: `test/support/test_container.dart`
- Test: `test/features/upcoming/app_data_provider_test.dart`, `test/features/reminders/reminder_rules_provider_test.dart`

**Interfaces:**
- Consumes: Repositories, `NotificationGateway`, `ReminderCoordinator`, `ReminderScheduler`, `Clock`, `applyImport`, `ParsedImport`, `ImportMode`.
- Produces:
  - `clockProvider: Provider<Clock>`, `eventRepositoryProvider: Provider<EventRepository>`, `settingsRepositoryProvider: Provider<SettingsRepository>`, `notificationGatewayProvider: Provider<NotificationGateway>`, `isIosProvider: Provider<bool>`, `reminderCoordinatorProvider: Provider<ReminderCoordinator>`, `importServiceProvider: Provider<ImportService>`
  - `appDataProvider: AsyncNotifierProvider<AppDataNotifier, AppData>`; `AppDataNotifier { bool wasCorruptOnLoad; Future<ImportOutcome> applyParsedImport(ParsedImport parsed, ImportMode mode); Future<void> updateWasteType(WasteType type); Future<void> clearAll(); }`
  - `reminderRulesProvider: AsyncNotifierProvider<ReminderRulesNotifier, List<ReminderRule>>`; `ReminderRulesNotifier { Future<void> add(ReminderRule rule); Future<void> update(ReminderRule rule); Future<void> remove(String id); }`
  - `reminderSyncProvider: Provider<ReminderSync>`; `ReminderSync { Future<void> rescheduleAll(); Future<void> rescheduleIfStale(); }`
  - Test-Helfer: `ProviderContainer createTestContainer({InMemoryEventRepository? events, InMemorySettingsRepository? settings, FakeNotificationGateway? gateway, Clock? clock, bool isIos = false})`

- [ ] **Step 1: Tests schreiben**

`test/support/test_container.dart`:

```dart
import 'package:abfallkalender/app/infrastructure_providers.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_notification_gateway.dart';
import 'in_memory_repositories.dart';

List<Override> testOverrides({
  InMemoryEventRepository? events,
  InMemorySettingsRepository? settings,
  FakeNotificationGateway? gateway,
  Clock? clock,
  bool isIos = false,
}) =>
    [
      eventRepositoryProvider.overrideWithValue(events ?? InMemoryEventRepository()),
      settingsRepositoryProvider.overrideWithValue(settings ?? InMemorySettingsRepository()),
      notificationGatewayProvider.overrideWithValue(gateway ?? FakeNotificationGateway()),
      clockProvider.overrideWithValue(clock ?? FixedClock(DateTime(2026, 1, 1, 12))),
      isIosProvider.overrideWithValue(isIos),
    ];

ProviderContainer createTestContainer({
  InMemoryEventRepository? events,
  InMemorySettingsRepository? settings,
  FakeNotificationGateway? gateway,
  Clock? clock,
  bool isIos = false,
}) =>
    ProviderContainer(
      overrides: testOverrides(
        events: events, settings: settings, gateway: gateway, clock: clock, isIos: isIos,
      ),
    );
```

`test/features/upcoming/app_data_provider_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/import/domain/apply_import.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:abfallkalender/features/upcoming/providers/app_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

void main() {
  test('loads from repository and exposes corrupt flag', () async {
    final repo = InMemoryEventRepository()..corruptOnLoad = true;
    final c = createTestContainer(events: repo);
    final data = await c.read(appDataProvider.future);
    expect(data.events, isEmpty);
    expect(c.read(appDataProvider.notifier).wasCorruptOnLoad, isTrue);
  });

  test('applyParsedImport saves, updates state and reschedules reminders', () async {
    final repo = InMemoryEventRepository();
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);

    final parsed = ParsedImport(
      sourceId: 'file:a',
      pickups: [RawPickup(date: DateTime(2026, 1, 5), rawName: 'Biotonne')],
      warnings: const [],
    );
    final out = await c.read(appDataProvider.notifier).applyParsedImport(parsed, ImportMode.merge);
    expect(out.imported, 1);
    expect(repo.saveCount, 1);
    expect(c.read(appDataProvider).value!.events.length, 1);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled.length, 2); // Vortag + Abholtag mit Standardregeln
  });

  test('updateWasteType replaces type and reschedules', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    ));
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).updateWasteType(
          const WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf', notificationsEnabled: false),
        );
    expect(repo.data.wasteTypes.single.notificationsEnabled, isFalse);
    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelAllCount, 1);
  });

  test('clearAll empties data and cancels notifications', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    ));
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).clearAll();
    expect(repo.data.events, isEmpty);
    expect(repo.data.wasteTypes, isEmpty);
    expect(gateway.cancelAllCount, 1);
  });
}
```

`test/features/reminders/reminder_rules_provider_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/providers/reminder_rules_provider.dart';
import 'package:abfallkalender/features/reminders/providers/reminder_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

final seeded = AppData(
  events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
  wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
);

void main() {
  test('defaults when nothing saved', () async {
    final c = createTestContainer();
    final rules = await c.read(reminderRulesProvider.future);
    expect(rules.length, 2);
  });

  test('loads saved rules', () async {
    final settings = InMemorySettingsRepository()
      ..rules = [const ReminderRule(id: 'r1', daysBefore: 2, hour: 9, minute: 15)];
    final c = createTestContainer(settings: settings);
    final rules = await c.read(reminderRulesProvider.future);
    expect(rules.single.id, 'r1');
  });

  test('add, update, remove persist and reschedule; add respects max', () async {
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(
      settings: settings, gateway: gateway, events: InMemoryEventRepository(seeded),
    );
    final notifier = c.read(reminderRulesProvider.notifier);
    await c.read(reminderRulesProvider.future);

    await notifier.add(const ReminderRule(id: 'n1', daysBefore: 2, hour: 9, minute: 0));
    expect(settings.rules!.length, 3);
    expect(gateway.scheduled.length, 3);

    await notifier.update(const ReminderRule(id: 'n1', daysBefore: 2, hour: 9, minute: 0, enabled: false));
    expect(gateway.scheduled.length, 2);

    await notifier.remove('n1');
    expect(settings.rules!.length, 2);

    for (var i = 0; i < 5; i++) {
      await notifier.add(ReminderRule(id: 'x$i', daysBefore: 1, hour: 8 + i, minute: 0));
    }
    expect(settings.rules!.length, ReminderRule.maxRules);
  });

  test('rescheduleIfStale only runs after 12 hours', () async {
    final settings = InMemorySettingsRepository()..lastScheduleRun = DateTime(2026, 1, 1, 6);
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(settings: settings, gateway: gateway, events: InMemoryEventRepository(seeded));
    await c.read(reminderSyncProvider).rescheduleIfStale(); // now = 12:00, 6h alt
    expect(gateway.cancelAllCount, 0);
    settings.lastScheduleRun = DateTime(2025, 12, 31, 6);
    await c.read(reminderSyncProvider).rescheduleIfStale();
    expect(gateway.cancelAllCount, 1);
    expect(settings.lastScheduleRun, DateTime(2026, 1, 1, 12));
  });

  test('iOS uses 60 limit with hint, android 200 without', () async {
    final many = AppData(
      events: [for (var d = 1; d <= 100; d++) PickupEvent(date: DateTime(2026, 1, 1).add(Duration(days: d)), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: seeded.wasteTypes,
    );
    final ios = FakeNotificationGateway();
    final cIos = createTestContainer(gateway: ios, events: InMemoryEventRepository(many), isIos: true);
    await cIos.read(reminderSyncProvider).rescheduleAll();
    expect(ios.scheduled.length, 61);

    final android = FakeNotificationGateway();
    final cAndroid = createTestContainer(gateway: android, events: InMemoryEventRepository(many));
    await cAndroid.read(reminderSyncProvider).rescheduleAll();
    expect(android.scheduled.length, 200);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/upcoming test/features/reminders
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/app/infrastructure_providers.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../features/import/domain/import_service.dart';
import '../features/reminders/domain/notification_gateway.dart';
import '../features/reminders/domain/reminder_coordinator.dart';
import '../features/reminders/domain/reminder_scheduler.dart';

final clockProvider = Provider<Clock>((_) => const SystemClock());

final eventRepositoryProvider = Provider<EventRepository>(
  (_) => throw UnimplementedError('eventRepositoryProvider muss in main überschrieben werden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => throw UnimplementedError('settingsRepositoryProvider muss in main überschrieben werden'),
);

final notificationGatewayProvider = Provider<NotificationGateway>(
  (_) => throw UnimplementedError('notificationGatewayProvider muss in main überschrieben werden'),
);

final isIosProvider = Provider<bool>((_) => Platform.isIOS);

final importServiceProvider = Provider<ImportService>((_) => ImportService());

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final isIos = ref.watch(isIosProvider);
  return ReminderCoordinator(
    gateway: ref.watch(notificationGatewayProvider),
    scheduler: ReminderScheduler(),
    clock: ref.watch(clockProvider),
    maxPending: isIos ? ReminderCoordinator.iosMaxPending : ReminderCoordinator.androidMaxPending,
    addRefreshHint: isIos,
  );
});
```

`lib/features/reminders/providers/reminder_sync.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../upcoming/providers/app_data_provider.dart';
import 'reminder_rules_provider.dart';

class ReminderSync {
  ReminderSync(this._ref);

  static const staleAfter = Duration(hours: 12);

  final Ref _ref;

  Future<void> rescheduleAll() async {
    final data = await _ref.read(appDataProvider.future);
    final rules = await _ref.read(reminderRulesProvider.future);
    await _ref.read(reminderCoordinatorProvider).reschedule(
          events: data.events,
          wasteTypes: data.wasteTypes,
          rules: rules,
        );
    await _ref.read(settingsRepositoryProvider).saveLastScheduleRun(_ref.read(clockProvider).now());
  }

  Future<void> rescheduleIfStale() async {
    final last = await _ref.read(settingsRepositoryProvider).loadLastScheduleRun();
    final now = _ref.read(clockProvider).now();
    if (last != null && now.difference(last) < staleAfter) return;
    await rescheduleAll();
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) => ReminderSync(ref));
```

`lib/features/upcoming/providers/app_data_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';
import '../../import/domain/apply_import.dart';
import '../../import/domain/parsed_import.dart';
import '../../reminders/providers/reminder_sync.dart';

class AppDataNotifier extends AsyncNotifier<AppData> {
  bool wasCorruptOnLoad = false;

  @override
  Future<AppData> build() async {
    final result = await ref.read(eventRepositoryProvider).load();
    wasCorruptOnLoad = result.wasCorrupt;
    return result.data;
  }

  AppData get _current => state.value ?? AppData.empty;

  Future<void> _commit(AppData data) async {
    await ref.read(eventRepositoryProvider).save(data);
    state = AsyncData(data);
    await ref.read(reminderSyncProvider).rescheduleAll();
  }

  Future<ImportOutcome> applyParsedImport(ParsedImport parsed, ImportMode mode) async {
    final outcome = applyImport(current: _current, parsed: parsed, mode: mode);
    await _commit(outcome.data);
    return outcome;
  }

  Future<void> updateWasteType(WasteType type) async {
    final types = _current.wasteTypes.map((t) => t.id == type.id ? type : t).toList();
    await _commit(_current.copyWith(wasteTypes: types));
  }

  Future<void> clearAll() => _commit(AppData.empty);
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, AppData>(AppDataNotifier.new);
```

`lib/features/reminders/providers/reminder_rules_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/reminder_rule.dart';
import 'reminder_sync.dart';

class ReminderRulesNotifier extends AsyncNotifier<List<ReminderRule>> {
  @override
  Future<List<ReminderRule>> build() async {
    final saved = await ref.read(settingsRepositoryProvider).loadRules();
    return saved ?? ReminderRule.defaults();
  }

  List<ReminderRule> get _current => state.value ?? ReminderRule.defaults();

  Future<void> _commit(List<ReminderRule> rules) async {
    await ref.read(settingsRepositoryProvider).saveRules(rules);
    state = AsyncData(rules);
    await ref.read(reminderSyncProvider).rescheduleAll();
  }

  Future<void> add(ReminderRule rule) async {
    if (_current.length >= ReminderRule.maxRules) return;
    await _commit([..._current, rule]);
  }

  Future<void> update(ReminderRule rule) =>
      _commit(_current.map((r) => r.id == rule.id ? rule : r).toList());

  Future<void> remove(String id) => _commit(_current.where((r) => r.id != id).toList());
}

final reminderRulesProvider =
    AsyncNotifierProvider<ReminderRulesNotifier, List<ReminderRule>>(ReminderRulesNotifier.new);
```

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/upcoming test/features/reminders
```

Erwartet: `All tests passed!`. Falls Riverpod einen Fehler über zirkuläre Abhängigkeit meldet: `ReminderSync` nutzt nur `ref.read`, nie `ref.watch`, das ist Absicht und erlaubt.

- [ ] **Step 5: Commit**

```powershell
git add lib/app lib/features test/support test/features
git commit -m "Add Riverpod providers for app data, reminder rules and sync`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 13: URL-Abo (HttpSource, SubscriptionNotifier)

**Files:**
- Create: `lib/features/import/domain/http_source.dart`, `lib/features/import/data/http_source_impl.dart`, `lib/features/import/providers/subscription_provider.dart`
- Modify: `lib/app/infrastructure_providers.dart` (Provider `httpSourceProvider` ergänzen), `test/support/test_container.dart` (Override ergänzen)
- Create: `test/support/fake_http_source.dart`
- Test: `test/features/import/subscription_provider_test.dart`

**Interfaces:**
- Consumes: `ImportService`, `AppDataNotifier.applyParsedImport`, `SettingsRepository`, `Clock`.
- Produces:
  - `class HttpSourceException implements Exception { String message; }`
  - `abstract class HttpSource { Future<List<int>> getBytes(Uri uri); }`
  - `class HttpSourceImpl implements HttpSource` (http GET, 20 s Timeout, nur http/https, Status 200)
  - `httpSourceProvider: Provider<HttpSource>`
  - `subscriptionProvider: AsyncNotifierProvider<SubscriptionNotifier, Subscription?>`; `SubscriptionNotifier { Future<Result<ParsedImport>> fetchAndParse(String url); Future<void> activate(String url); Future<bool> refresh({bool force = false}); Future<void> remove(); }`
  - `FakeHttpSource { Map<String, List<int>> responses; Object? error; List<Uri> requested; }`

- [ ] **Step 1: Tests schreiben**

`test/support/fake_http_source.dart`:

```dart
import 'package:abfallkalender/features/import/domain/http_source.dart';

class FakeHttpSource implements HttpSource {
  final Map<String, List<int>> responses = {};
  Object? error;
  final List<Uri> requested = [];

  @override
  Future<List<int>> getBytes(Uri uri) async {
    requested.add(uri);
    if (error != null) throw error!;
    final body = responses[uri.toString()];
    if (body == null) throw HttpSourceException('Server antwortete mit Status 404.');
    return body;
  }
}
```

In `test/support/test_container.dart` den Parameter `FakeHttpSource? http` ergänzen und in `testOverrides` die Zeile `httpSourceProvider.overrideWithValue(http ?? FakeHttpSource()),` hinzufügen (Import `fake_http_source.dart`). `createTestContainer` reicht `http` durch.

`test/features/import/subscription_provider_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/features/import/providers/subscription_provider.dart';
import 'package:abfallkalender/features/upcoming/providers/app_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_source.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

const url = 'https://landkreis.example/abfuhr.ics';

void main() {
  final ics = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();

  test('activate stores subscription, imports events and sets lastFetched', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final clock = FixedClock(DateTime(2026, 1, 1, 12));
    final c = createTestContainer(http: http, settings: settings, clock: clock);
    await c.read(appDataProvider.future);

    await c.read(subscriptionProvider.notifier).activate(url);

    expect(settings.subscription!.url, url);
    expect(settings.subscription!.lastFetched, DateTime(2026, 1, 1, 12));
    expect(settings.subscription!.lastError, isNull);
    expect(c.read(appDataProvider).value!.events.length, 94);
    expect(c.read(appDataProvider).value!.events.first.sourceId, 'url:landkreis.example');
  });

  test('refresh skips when fetched less than 24h ago unless forced', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2026, 1, 1, 2));
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);

    expect(await c.read(subscriptionProvider.notifier).refresh(), isFalse);
    expect(http.requested, isEmpty);
    expect(await c.read(subscriptionProvider.notifier).refresh(force: true), isTrue);
    expect(http.requested.length, 1);
  });

  test('refresh runs when older than 24h', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2025, 12, 30));
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);
    expect(await c.read(subscriptionProvider.notifier).refresh(), isTrue);
  });

  test('html response sets lastError and leaves data untouched', () async {
    final http = FakeHttpSource()..responses[url] = utf8.encode('<html>Not an ics</html>');
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: url);
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);

    expect(await c.read(subscriptionProvider.notifier).refresh(force: true), isFalse);
    expect(settings.subscription!.lastError, isNotNull);
    expect(c.read(appDataProvider).value!.events, isEmpty);
  });

  test('network error sets lastError message', () async {
    final http = FakeHttpSource()..error = const SocketException('offline');
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: url);
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);
    await c.read(subscriptionProvider.notifier).refresh(force: true);
    expect(settings.subscription!.lastError, contains('Netzwerk'));
  });

  test('remove clears subscription but keeps events', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.notifier).activate(url);
    await c.read(subscriptionProvider.notifier).remove();
    expect(settings.subscription, isNull);
    expect(c.read(subscriptionProvider).value, isNull);
    expect(c.read(appDataProvider).value!.events.length, 94);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import/subscription_provider_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/http_source.dart`:

```dart
class HttpSourceException implements Exception {
  const HttpSourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class HttpSource {
  Future<List<int>> getBytes(Uri uri);
}
```

`lib/features/import/data/http_source_impl.dart`:

```dart
import 'dart:async';

import 'package:http/http.dart' as http;

import '../domain/http_source.dart';

class HttpSourceImpl implements HttpSource {
  static const timeout = Duration(seconds: 20);

  @override
  Future<List<int>> getBytes(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const HttpSourceException('Nur http- und https-Adressen werden unterstützt.');
    }
    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const HttpSourceException('Zeitüberschreitung beim Laden.');
    }
    if (response.statusCode != 200) {
      throw HttpSourceException('Server antwortete mit Status ${response.statusCode}.');
    }
    return response.bodyBytes;
  }
}
```

In `lib/app/infrastructure_providers.dart` ergänzen:

```dart
import '../features/import/data/http_source_impl.dart';
import '../features/import/domain/http_source.dart';

final httpSourceProvider = Provider<HttpSource>((_) => HttpSourceImpl());
```

`lib/features/import/providers/subscription_provider.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/result.dart';
import '../../../data/models/subscription.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../domain/apply_import.dart';
import '../domain/http_source.dart';
import '../domain/parsed_import.dart';

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  static const refreshAfter = Duration(hours: 24);

  @override
  Future<Subscription?> build() => ref.read(settingsRepositoryProvider).loadSubscription();

  Future<void> _commit(Subscription? sub) async {
    await ref.read(settingsRepositoryProvider).saveSubscription(sub);
    state = AsyncData(sub);
  }

  static String sourceIdFor(Uri uri) => 'url:${uri.host}';

  /// Lädt und parst, ohne etwas zu speichern (für Vorschau).
  Future<Result<ParsedImport>> fetchAndParse(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return const Err('Bitte eine gültige http- oder https-Adresse eingeben.');
    }
    try {
      final bytes = await ref.read(httpSourceProvider).getBytes(uri);
      return ref.read(importServiceProvider).parseBytes(bytes: bytes, sourceId: sourceIdFor(uri));
    } on HttpSourceException catch (e) {
      return Err(e.message);
    } on SocketException {
      return const Err('Keine Netzwerkverbindung.');
    } catch (e) {
      return Err('Laden fehlgeschlagen: $e');
    }
  }

  /// Speichert das Abo und führt einen ersten erzwungenen Abruf aus.
  Future<void> activate(String url) async {
    await _commit(Subscription(url: url.trim()));
    await refresh(force: true);
  }

  /// Gibt `true` zurück, wenn Daten erfolgreich übernommen wurden.
  Future<bool> refresh({bool force = false}) async {
    final sub = state.value ?? await future;
    if (sub == null) return false;
    final now = ref.read(clockProvider).now();
    if (!force && sub.lastFetched != null && now.difference(sub.lastFetched!) < refreshAfter) {
      return false;
    }
    final result = await fetchAndParse(sub.url);
    return result.when(
      ok: (parsed, _) async {
        await ref.read(appDataProvider.notifier).applyParsedImport(parsed, ImportMode.merge);
        await _commit(sub.copyWith(lastFetched: now, clearError: true));
        return true;
      },
      err: (message) async {
        await _commit(sub.copyWith(lastError: message));
        return false;
      },
    );
  }

  Future<void> remove() => _commit(null);
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(SubscriptionNotifier.new);
```

Hinweis: `result.when` liefert hier `Future<bool>`, deshalb `return result.when(...)` ohne weiteres `await` innerhalb der Lambdas nötig; der Aufrufer awaitet das Ergebnis. Falls der Analyzer meckert, `final r = result.when<Future<bool>>(...); return r;` schreiben.

Netzwerkfehler-Text: `SocketException` wird zu „Keine Netzwerkverbindung." und der Test prüft auf „Netzwerk".

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import/subscription_provider_test.dart
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`

- [ ] **Step 5: Commit**

```powershell
git add lib/app lib/features/import test/support test/features/import
git commit -m "Add ICS URL subscription with auto refresh`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 14: Theme, App-Shell, Bootstrap, Lifecycle, Widget-Test-Helfer

**Files:**
- Create: `lib/app/theme.dart`, `lib/app/app.dart`, `lib/app/app_shell.dart`, `lib/app/lifecycle_service.dart`, `lib/features/waste_types/ui/waste_icons.dart`
- Modify: `lib/main.dart`
- Create: `test/support/pump_app.dart`
- Test: `test/app/app_shell_test.dart`, `test/app/lifecycle_service_test.dart`

**Interfaces:**
- Consumes: alle Provider aus Task 12/13, `LocalNotificationsGateway`, Repositories.
- Produces:
  - `ThemeData buildLightTheme()`, `ThemeData buildDarkTheme()`
  - `class AbfallkalenderApp extends StatelessWidget` (MaterialApp mit Theme, Lokalisierung, `home: AppShell()`)
  - `class AppShell extends ConsumerStatefulWidget` (NavigationBar mit drei Tabs, Platzhalter-Screens, die in Task 15/16/18 ersetzt werden; `WidgetsBindingObserver` ruft `LifecycleService.onResumed()`)
  - `class LifecycleService { Future<void> onStart(); Future<void> onResumed(); }`, `lifecycleServiceProvider`
  - `IconData wasteIconFor(String key)`
  - Test-Helfer: `Future<void> pumpApp(WidgetTester tester, Widget child, {List<Override> overrides = const []})`

- [ ] **Step 1: Tests schreiben**

`test/support/pump_app.dart`:

```dart
import 'package:abfallkalender/app/theme.dart';
import 'package:abfallkalender/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

`test/app/app_shell_test.dart`:

```dart
import 'package:abfallkalender/app/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/test_container.dart';

void main() {
  testWidgets('shows three tabs and switches', (tester) async {
    await pumpApp(tester, const AppShell(), overrides: testOverrides());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-calendar')), findsOneWidget);
  });
}
```

`test/app/lifecycle_service_test.dart`:

```dart
import 'dart:io';

import 'package:abfallkalender/app/lifecycle_service.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_source.dart';
import '../support/fake_notification_gateway.dart';
import '../support/in_memory_repositories.dart';
import '../support/test_container.dart';

void main() {
  const url = 'https://a.example/x.ics';

  test('onStart reschedules when stale and refreshes stale subscription', () async {
    final gateway = FakeNotificationGateway();
    final http = FakeHttpSource()
      ..responses[url] = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2025, 12, 1));
    final c = createTestContainer(
      gateway: gateway, http: http, settings: settings,
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );
    await c.read(lifecycleServiceProvider).onStart();
    expect(http.requested.length, 1);
    expect(gateway.cancelAllCount, greaterThanOrEqualTo(1));
    expect(settings.lastScheduleRun, isNotNull);
  });

  test('onResumed does nothing when everything is fresh', () async {
    final gateway = FakeNotificationGateway();
    final http = FakeHttpSource();
    final settings = InMemorySettingsRepository()
      ..lastScheduleRun = DateTime(2026, 1, 1, 10)
      ..subscription = Subscription(url: url, lastFetched: DateTime(2026, 1, 1, 10));
    final c = createTestContainer(
      gateway: gateway, http: http, settings: settings,
      events: InMemoryEventRepository(AppData(
        events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'b', sourceId: 's')],
        wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
      )),
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );
    await c.read(lifecycleServiceProvider).onResumed();
    expect(http.requested, isEmpty);
    expect(gateway.cancelAllCount, 0);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/app
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

const _seed = Color(0xFF2E7D32);

ThemeData _base(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    listTileTheme: const ListTileThemeData(minTileHeight: 56),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

ThemeData buildLightTheme() => _base(Brightness.light);
ThemeData buildDarkTheme() => _base(Brightness.dark);

/// Hellt dunkle Akzentfarben im Dark Theme leicht auf, damit der Kontrast stimmt.
Color accentFor(BuildContext context, int argb) {
  final color = Color(argb);
  if (Theme.of(context).brightness == Brightness.light) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
}
```

`lib/features/waste_types/ui/waste_icons.dart`:

```dart
import 'package:flutter/material.dart';

IconData wasteIconFor(String key) => switch (key) {
      'leaf' => Icons.eco_outlined,
      'recycle' => Icons.recycling_outlined,
      'paper' => Icons.description_outlined,
      'warning' => Icons.warning_amber_outlined,
      'bottle' => Icons.wine_bar_outlined,
      'sofa' => Icons.weekend_outlined,
      'tree' => Icons.park_outlined,
      _ => Icons.delete_outline,
    };
```

`lib/app/lifecycle_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/import/providers/subscription_provider.dart';
import '../features/reminders/providers/reminder_sync.dart';
import '../features/upcoming/providers/app_data_provider.dart';

class LifecycleService {
  LifecycleService(this._ref);
  final Ref _ref;

  Future<void> onStart() async {
    await _ref.read(appDataProvider.future);
    await _ref.read(subscriptionProvider.notifier).refresh();
    await _ref.read(reminderSyncProvider).rescheduleIfStale();
  }

  Future<void> onResumed() => onStart();
}

final lifecycleServiceProvider = Provider<LifecycleService>((ref) => LifecycleService(ref));
```

`lib/app/app_shell.dart` (Platzhalter-Screens werden in Task 15, 16 und 18 ersetzt):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'lifecycle_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(lifecycleServiceProvider).onStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(lifecycleServiceProvider).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          Center(key: Key('tab-home'), child: Text('home')),
          Center(key: Key('tab-calendar'), child: Text('calendar')),
          Center(key: Key('tab-settings'), child: Text('settings')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l10n.tabCalendar),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l10n.tabSettings),
        ],
      ),
    );
  }
}
```

Die Platzhalter-Texte sind absichtlich englisch, damit der Shell-Test die Tab-Labels eindeutig findet.

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_shell.dart';
import 'theme.dart';

class AbfallkalenderApp extends StatelessWidget {
  const AbfallkalenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }
}
```

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/infrastructure_providers.dart';
import 'data/repositories/json_file_event_repository.dart';
import 'data/repositories/prefs_settings_repository.dart';
import 'features/reminders/data/local_notifications_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final documents = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  final gateway = LocalNotificationsGateway();
  await gateway.initialize();

  runApp(
    ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(JsonFileEventRepository(documents)),
        settingsRepositoryProvider.overrideWithValue(PrefsSettingsRepository(prefs)),
        notificationGatewayProvider.overrideWithValue(gateway),
      ],
      child: const AbfallkalenderApp(),
    ),
  );
}
```

- [ ] **Step 4: Tests, Analyse und Emulator-Start**

```powershell
flutter gen-l10n
flutter test test/app
flutter analyze
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

Erwartet: Tests grün, App startet im Emulator mit drei Tabs. `q` beendet `flutter run`.

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "Add theme, app shell, bootstrap and lifecycle service`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 15: Startseite (Nächste Abholung, Liste, Leerzustände)

**Files:**
- Create: `lib/features/upcoming/domain/upcoming_groups.dart`, `lib/features/upcoming/ui/upcoming_screen.dart`, `lib/features/upcoming/ui/next_pickup_card.dart`, `lib/features/upcoming/ui/day_group_card.dart`, `lib/features/upcoming/ui/empty_state.dart`, `lib/features/upcoming/ui/waste_chip.dart`
- Modify: `lib/app/app_shell.dart` (Platzhalter „home" durch `UpcomingScreen` ersetzen)
- Test: `test/features/upcoming/upcoming_groups_test.dart`, `test/features/upcoming/upcoming_screen_test.dart`

**Interfaces:**
- Consumes: `appDataProvider`, `clockProvider`, `daysBetween`, `wasteIconFor`, `accentFor`, `AppLocalizations`.
- Produces:
  - `class DayGroup { DateTime date; List<WasteType> types; String? note; }`
  - `List<DayGroup> upcomingGroups({required AppData data, required DateTime now, int horizonDays = 28})`
  - `class UpcomingScreen extends ConsumerWidget` mit Callbacks `onImportFile`, `onEnterUrl` (werden in Task 17 verdrahtet; bis dahin `null` erlaubt)
  - `class WasteChip extends StatelessWidget { WasteType type; }`

- [ ] **Step 1: Tests schreiben**

`test/features/upcoming/upcoming_groups_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/upcoming/domain/upcoming_groups.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier', color: 2, icon: 'paper');
PickupEvent ev(DateTime d, String t, {String? note}) =>
    PickupEvent(date: d, wasteTypeId: t, sourceId: 's', note: note);

void main() {
  test('groups by day within horizon, sorted, includes today, excludes past', () {
    final data = AppData(
      events: [
        ev(DateTime(2025, 12, 31), 'bio'),
        ev(DateTime(2026, 1, 1), 'bio', note: 'bis 6:30'),
        ev(DateTime(2026, 1, 5), 'papier'),
        ev(DateTime(2026, 1, 5), 'bio'),
        ev(DateTime(2026, 3, 1), 'bio'),
      ],
      wasteTypes: const [bio, papier],
    );
    final groups = upcomingGroups(data: data, now: DateTime(2026, 1, 1, 15));
    expect(groups.length, 2);
    expect(groups[0].date, DateTime(2026, 1, 1));
    expect(groups[0].note, 'bis 6:30');
    expect(groups[1].types.map((t) => t.id), ['bio', 'papier']);
  });

  test('ignores events with unknown waste type', () {
    final data = AppData(events: [ev(DateTime(2026, 1, 2), 'x')], wasteTypes: const [bio]);
    expect(upcomingGroups(data: data, now: DateTime(2026, 1, 1)), isEmpty);
  });
}
```

`test/features/upcoming/upcoming_screen_test.dart`:

```dart
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/upcoming/ui/upcoming_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');
PickupEvent ev(DateTime d) => PickupEvent(date: d, wasteTypeId: 'bio', sourceId: 's', note: 'Tonne bis 6:30 Uhr');

void main() {
  testWidgets('empty state offers import buttons', (tester) async {
    await pumpApp(tester, const UpcomingScreen(), overrides: testOverrides());
    expect(find.text('Noch keine Termine'), findsOneWidget);
    expect(find.text('Datei importieren'), findsOneWidget);
    expect(find.text('URL eintragen'), findsOneWidget);
  });

  testWidgets('shows next pickup hero and list', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [ev(DateTime(2026, 1, 2)), ev(DateTime(2026, 1, 9))],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const UpcomingScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 1, 12))));
    expect(find.text('Nächste Abholung'), findsOneWidget);
    expect(find.text('Morgen'), findsWidgets);
    expect(find.text('Biotonne'), findsWidgets);
    expect(find.textContaining('6:30'), findsOneWidget);
    expect(find.text('in 8 Tagen'), findsOneWidget);
  });

  testWidgets('only past events shows no-upcoming state, not onboarding', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [ev(DateTime(2025, 6, 1))],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const UpcomingScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 1))));
    expect(find.text('Keine anstehenden Termine'), findsOneWidget);
    expect(find.text('Noch keine Termine'), findsNothing);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/upcoming
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/upcoming/domain/upcoming_groups.dart`:

```dart
import '../../../core/dates.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';

class DayGroup {
  const DayGroup({required this.date, required this.types, this.note});
  final DateTime date;
  final List<WasteType> types;
  final String? note;
}

List<DayGroup> upcomingGroups({
  required AppData data,
  required DateTime now,
  int horizonDays = 28,
}) {
  final typeById = {for (final t in data.wasteTypes) t.id: t};
  final today = now.dateOnly;
  final byDate = <String, DayGroup>{};
  for (final e in data.events) {
    final type = typeById[e.wasteTypeId];
    if (type == null) continue;
    final offset = daysBetween(today, e.date);
    if (offset < 0 || offset > horizonDays) continue;
    final key = e.date.isoDate;
    final existing = byDate[key];
    if (existing == null) {
      byDate[key] = DayGroup(date: e.date, types: [type], note: e.note);
    } else if (!existing.types.any((t) => t.id == type.id)) {
      byDate[key] = DayGroup(
        date: existing.date,
        types: [...existing.types, type]..sort((a, b) => a.displayName.compareTo(b.displayName)),
        note: existing.note ?? e.note,
      );
    }
  }
  return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}
```

`lib/features/upcoming/ui/waste_chip.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../waste_types/ui/waste_icons.dart';

class WasteChip extends StatelessWidget {
  const WasteChip({super.key, required this.type});
  final WasteType type;

  @override
  Widget build(BuildContext context) {
    final color = accentFor(context, type.color);
    return Chip(
      avatar: Icon(wasteIconFor(type.icon), size: 18, color: color),
      label: Text(type.displayName),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
```

`lib/features/upcoming/ui/next_pickup_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../waste_types/ui/waste_icons.dart';
import '../domain/upcoming_groups.dart';
import 'waste_chip.dart';

class NextPickupCard extends StatelessWidget {
  const NextPickupCard({super.key, required this.group, required this.daysFromNow});
  final DayGroup group;
  final int daysFromNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = group.types.first;
    final color = accentFor(context, primary.color);
    final relative = relativeLabel(l10n, daysFromNow);
    final absolute = DateFormat('EEEE, d. MMMM', 'de').format(group.date);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 8, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nextPickup, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                        child: Icon(wasteIconFor(primary.icon), color: color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(relative, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text(absolute, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final t in group.types) WasteChip(type: t)]),
                  if (group.note != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: Text(group.note!, style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String relativeLabel(AppLocalizations l10n, int days) => switch (days) {
      0 => l10n.today,
      1 => l10n.tomorrow,
      _ => l10n.inDays(days),
    };
```

`lib/features/upcoming/ui/day_group_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import 'next_pickup_card.dart' show relativeLabel;
import 'waste_chip.dart';

class DayGroupCard extends StatelessWidget {
  const DayGroupCard({super.key, required this.group, required this.daysFromNow});
  final DayGroup group;
  final int daysFromNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = accentFor(context, group.types.first.color);
    final title = daysFromNow <= 1 ? relativeLabel(l10n, daysFromNow) : DateFormat('EEEE, d. MMM', 'de').format(group.date);
    final subtitle = daysFromNow <= 1 ? DateFormat('d. MMMM', 'de').format(group.date) : relativeLabel(l10n, daysFromNow);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 6, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final t in group.types) WasteChip(type: t)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/upcoming/ui/empty_state.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.onImportFile, this.onEnterUrl});
  final VoidCallback? onImportFile;
  final VoidCallback? onEnterUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_outlined, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(l10n.emptyTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.emptyBody, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: onImportFile, icon: const Icon(Icons.upload_file), label: Text(l10n.importFile)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onEnterUrl, icon: const Icon(Icons.link), label: Text(l10n.enterUrl)),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/upcoming/ui/upcoming_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import '../providers/app_data_provider.dart';
import 'day_group_card.dart';
import 'empty_state.dart';
import 'next_pickup_card.dart';

class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key, this.onImportFile, this.onEnterUrl});
  final VoidCallback? onImportFile;
  final VoidCallback? onEnterUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider).now();
    final data = ref.watch(appDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          if (data.events.isEmpty) {
            return EmptyState(onImportFile: onImportFile, onEnterUrl: onEnterUrl);
          }
          final groups = upcomingGroups(data: data, now: now);
          if (groups.isEmpty) {
            return _NoUpcoming(onImportFile: onImportFile);
          }
          final today = now.dateOnly;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              NextPickupCard(group: groups.first, daysFromNow: daysBetween(today, groups.first.date)),
              const SizedBox(height: 16),
              for (final g in groups.skip(1)) ...[
                DayGroupCard(group: g, daysFromNow: daysBetween(today, g.date)),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoUpcoming extends StatelessWidget {
  const _NoUpcoming({this.onImportFile});
  final VoidCallback? onImportFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(l10n.noUpcoming, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.noUpcomingHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: onImportFile, icon: const Icon(Icons.upload_file), label: Text(l10n.importFile)),
          ],
        ),
      ),
    );
  }
}
```

In `lib/app/app_shell.dart` den Platzhalter `Center(key: Key('tab-home'), ...)` durch `const UpcomingScreen()` ersetzen (Import ergänzen).

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/upcoming test/app
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`. Falls `DateFormat(..., 'de')` im Test eine `LocaleDataException` wirft: `pumpApp` lädt über `AppLocalizations.localizationsDelegates` die `GlobalMaterialLocalizations`, die die Datumssymbole initialisieren. Prüfen, dass der Screen unterhalb der `MaterialApp` aus `pumpApp` liegt.

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "Add upcoming screen with next pickup card and empty states`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 16: Kalender-Tab

**Files:**
- Create: `lib/features/calendar/domain/events_by_day.dart`, `lib/features/calendar/ui/calendar_screen.dart`, `lib/features/calendar/ui/legend.dart`
- Modify: `lib/app/app_shell.dart` (Platzhalter „calendar" durch `CalendarScreen` ersetzen)
- Test: `test/features/calendar/events_by_day_test.dart`, `test/features/calendar/calendar_screen_test.dart`

**Interfaces:**
- Consumes: `appDataProvider`, `clockProvider`, `accentFor`, `wasteIconFor`, `WasteChip`.
- Produces:
  - `Map<String, List<WasteType>> eventsByDay(AppData data)` (Schlüssel `isoDate`, Typen sortiert nach Name, dedupliziert)
  - `class CalendarScreen extends ConsumerStatefulWidget`
  - `class Legend extends StatelessWidget { List<WasteType> types; }`

- [ ] **Step 1: Tests schreiben**

`test/features/calendar/events_by_day_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/calendar/domain/events_by_day.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier', color: 2, icon: 'paper');

void main() {
  test('maps iso date to sorted unique types, ignoring unknown', () {
    final data = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'papier', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'unknown', sourceId: 's'),
      ],
      wasteTypes: const [bio, papier],
    );
    final m = eventsByDay(data);
    expect(m.keys, ['2026-01-05']);
    expect(m['2026-01-05']!.map((t) => t.id), ['papier', 'bio']);
  });
}
```

`test/features/calendar/calendar_screen_test.dart`:

```dart
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/calendar/ui/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');

void main() {
  testWidgets('shows calendar, legend, markers and day details on tap', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 15), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const CalendarScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 10))));

    expect(find.byType(TableCalendar<WasteType>), findsOneWidget);
    expect(find.text('Legende'), findsOneWidget);
    expect(find.byKey(const Key('marker-2026-01-15-bio')), findsOneWidget);
    expect(find.text('Keine Abholung an diesem Tag'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Keine Abholung an diesem Tag'), findsNothing);
    expect(find.text('Biotonne'), findsWidgets);
  });

  testWidgets('Heute button exists', (tester) async {
    await pumpApp(tester, const CalendarScreen(), overrides: testOverrides());
    expect(find.byTooltip('Heute'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/calendar
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/calendar/domain/events_by_day.dart`:

```dart
import '../../../core/dates.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';

Map<String, List<WasteType>> eventsByDay(AppData data) {
  final typeById = {for (final t in data.wasteTypes) t.id: t};
  final out = <String, List<WasteType>>{};
  for (final e in data.events) {
    final type = typeById[e.wasteTypeId];
    if (type == null) continue;
    final list = out.putIfAbsent(e.date.isoDate, () => []);
    if (!list.any((t) => t.id == type.id)) {
      list.add(type);
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
  }
  return out;
}
```

`lib/features/calendar/ui/legend.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../waste_types/ui/waste_icons.dart';

class Legend extends StatelessWidget {
  const Legend({super.key, required this.types});
  final List<WasteType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).legend, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final t in types)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(wasteIconFor(t.icon), size: 16, color: accentFor(context, t.color)),
                  const SizedBox(width: 4),
                  Text(t.displayName, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
```

`lib/features/calendar/ui/calendar_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../../upcoming/ui/waste_chip.dart';
import '../domain/events_by_day.dart';
import 'legend.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = ref.read(clockProvider).now().dateOnly;
    _focused = today;
    _selected = today;
  }

  void _jumpToToday() {
    final today = ref.read(clockProvider).now().dateOnly;
    setState(() {
      _focused = today;
      _selected = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(appDataProvider).value;
    final byDay = data == null ? const <String, List<WasteType>>{} : eventsByDay(data);
    final types = data?.wasteTypes ?? const <WasteType>[];
    final selectedTypes = byDay[_selected.isoDate] ?? const <WasteType>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabCalendar),
        actions: [
          IconButton(tooltip: l10n.calendarToday, icon: const Icon(Icons.today), onPressed: _jumpToToday),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TableCalendar<WasteType>(
            locale: 'de_DE',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
            headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              markersMaxCount: 4,
              cellMargin: const EdgeInsets.all(4),
            ),
            selectedDayPredicate: (day) => isSameDay(day, _selected),
            eventLoader: (day) => byDay[day.isoDate] ?? const [],
            onDaySelected: (selected, focused) => setState(() {
              _selected = selected.dateOnly;
              _focused = focused;
            }),
            onPageChanged: (focused) => _focused = focused,
            calendarBuilders: CalendarBuilders<WasteType>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in events.take(4))
                        Container(
                          key: Key('marker-${day.isoDate}-${t.id}'),
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: accentFor(context, t.color), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: selectedTypes.isEmpty
                  ? Text(l10n.noPickupsThisDay, style: theme.textTheme.bodyMedium)
                  : Wrap(spacing: 8, runSpacing: 8, children: [for (final t in selectedTypes) WasteChip(type: t)]),
            ),
          ),
          const SizedBox(height: 16),
          if (types.isNotEmpty) Legend(types: types),
        ],
      ),
    );
  }
}
```

In `lib/app/app_shell.dart` den Platzhalter „calendar" durch `const CalendarScreen(key: Key('tab-calendar'))` ersetzen.

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/calendar test/app
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`. Falls `find.text('15')` mehrere Treffer hat (angrenzende Monate), `find.text('15').first` verwenden.

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "Add calendar screen with markers, day details and legend`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 17: Import-Flow (Datei, URL, Vorschau, Berechtigungsdialog)

**Files:**
- Create: `lib/features/import/ui/import_flow.dart`, `lib/features/import/ui/import_preview_dialog.dart`, `lib/features/import/ui/url_dialog.dart`, `lib/features/import/ui/permission_dialog.dart`
- Create: `lib/features/import/domain/file_source.dart`, `lib/features/import/data/file_picker_source.dart`
- Modify: `lib/app/infrastructure_providers.dart` (`fileSourceProvider`), `lib/app/app_shell.dart` (Callbacks an `UpcomingScreen`), `test/support/test_container.dart` (Override), `test/support/fake_file_source.dart` (neu)
- Test: `test/features/import/import_flow_test.dart`

**Interfaces:**
- Consumes: `importServiceProvider`, `appDataProvider`, `subscriptionProvider`, `notificationGatewayProvider`.
- Produces:
  - `class PickedFile { String name; List<int> bytes; }`, `abstract class FileSource { Future<PickedFile?> pick(); }`, `class FilePickerSource implements FileSource`, `fileSourceProvider`
  - `class ImportFlow { ImportFlow(WidgetRef ref); Future<void> importFromFile(BuildContext context); Future<void> importFromUrl(BuildContext context); }`
  - `Future<ImportMode?> showImportPreviewDialog(BuildContext context, ParsedImport parsed, List<WasteType> resolvedTypes)`
  - `Future<String?> showUrlDialog(BuildContext context)`
  - `Future<void> ensureNotificationPermission(BuildContext context, WidgetRef ref)`
  - `FakeFileSource { PickedFile? next; }`

- [ ] **Step 1: Tests schreiben**

`test/support/fake_file_source.dart`:

```dart
import 'package:abfallkalender/features/import/domain/file_source.dart';

class FakeFileSource implements FileSource {
  PickedFile? next;
  @override
  Future<PickedFile?> pick() async => next;
}
```

In `test/support/test_container.dart` den Parameter `FakeFileSource? files` ergänzen und `fileSourceProvider.overrideWithValue(files ?? FakeFileSource())` in `testOverrides` aufnehmen.

`test/features/import/import_flow_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/features/import/domain/file_source.dart';
import 'package:abfallkalender/features/import/ui/import_flow.dart';
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/upcoming/ui/upcoming_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_source.dart';
import '../../support/fake_http_source.dart';
import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ImportFlow(ref);
    return UpcomingScreen(
      onImportFile: () => flow.importFromFile(context),
      onEnterUrl: () => flow.importFromUrl(context),
    );
  }
}

void main() {
  final ics = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();

  testWidgets('file import: preview, merge, success, permission dialog', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'a.ics', bytes: ics);
    final repo = InMemoryEventRepository();
    final gateway = FakeNotificationGateway();
    await pumpApp(tester, const _Host(),
        overrides: testOverrides(files: files, events: repo, gateway: gateway));

    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();

    expect(find.text('Import prüfen'), findsOneWidget);
    expect(find.textContaining('94 Termine'), findsOneWidget);
    expect(find.text('Biotonne'), findsOneWidget);
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();

    expect(repo.data.events.length, 94);
    expect(find.text('Erinnerungen erlauben'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(gateway.requestCount, 1);
    expect(find.textContaining('94 Termine importiert'), findsOneWidget);
  });

  testWidgets('file import: cancel in preview changes nothing', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'a.ics', bytes: ics);
    final repo = InMemoryEventRepository();
    await pumpApp(tester, const _Host(), overrides: testOverrides(files: files, events: repo));
    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repo.saveCount, 0);
  });

  testWidgets('file import: unparsable file shows error', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'x.txt', bytes: utf8.encode('hallo'));
    await pumpApp(tester, const _Host(), overrides: testOverrides(files: files));
    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();
    expect(find.text('Import fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('Datum'), findsOneWidget);
  });

  testWidgets('url import: dialog, preview, activates subscription', (tester) async {
    const url = 'https://lk.example/a.ics';
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.granted;
    await pumpApp(tester, const _Host(),
        overrides: testOverrides(http: http, settings: settings, gateway: gateway));

    await tester.tap(find.text('URL eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Import prüfen'), findsOneWidget);
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();

    expect(settings.subscription!.url, url);
    expect(find.text('Erinnerungen erlauben'), findsNothing);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/import/import_flow_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/import/domain/file_source.dart`:

```dart
class PickedFile {
  const PickedFile({required this.name, required this.bytes});
  final String name;
  final List<int> bytes;
}

abstract class FileSource {
  Future<PickedFile?> pick();
}
```

`lib/features/import/data/file_picker_source.dart`:

```dart
import 'package:file_picker/file_picker.dart';

import '../domain/file_source.dart';

class FilePickerSource implements FileSource {
  @override
  Future<PickedFile?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }
}
```

In `lib/app/infrastructure_providers.dart`:

```dart
import '../features/import/data/file_picker_source.dart';
import '../features/import/domain/file_source.dart';

final fileSourceProvider = Provider<FileSource>((_) => FilePickerSource());
```

`lib/features/import/ui/url_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

Future<String?> showUrlDialog(BuildContext context, {String? initial}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.urlDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(hintText: l10n.urlDialogHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}
```

`lib/features/import/ui/import_preview_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/ui/waste_chip.dart';
import '../domain/apply_import.dart';
import '../domain/parsed_import.dart';

Future<ImportMode?> showImportPreviewDialog(
  BuildContext context,
  ParsedImport parsed,
  List<WasteType> resolvedTypes,
) {
  final l10n = AppLocalizations.of(context);
  final fmt = DateFormat('d. MMM yyyy', 'de');
  return showDialog<ImportMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importPreviewSummary(parsed.pickups.length, resolvedTypes.length)),
            Text(l10n.importPreviewRange(fmt.format(parsed.firstDate), fmt.format(parsed.lastDate))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in resolvedTypes) WasteChip(type: t)]),
            if (parsed.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.warnings, style: Theme.of(context).textTheme.labelLarge),
              for (final w in parsed.warnings) Text('• $w'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, ImportMode.replace),
          child: Text(l10n.importModeReplace),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ImportMode.merge),
          child: Text(l10n.importModeMerge),
        ),
      ],
    ),
  );
}
```

`lib/features/import/ui/permission_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../reminders/domain/notification_gateway.dart';

/// Fragt die Berechtigung an, falls sie noch nicht erteilt ist. Erklärender Dialog davor.
Future<void> ensureNotificationPermission(BuildContext context, WidgetRef ref) async {
  final gateway = ref.read(notificationGatewayProvider);
  if (await gateway.permissionStatus() == NotificationPermission.granted) return;
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.permissionDialogTitle),
      content: Text(l10n.permissionDialogBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.permissionDialogAllow)),
      ],
    ),
  );
  if (proceed == true) await gateway.requestPermission();
}
```

`lib/features/import/ui/import_flow.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/result.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import '../domain/apply_import.dart';
import '../domain/parsed_import.dart';
import '../providers/subscription_provider.dart';
import 'import_preview_dialog.dart';
import 'permission_dialog.dart';
import 'url_dialog.dart';

class ImportFlow {
  ImportFlow(this.ref);
  final WidgetRef ref;

  Future<void> importFromFile(BuildContext context) async {
    final picked = await ref.read(fileSourceProvider).pick();
    if (picked == null || !context.mounted) return;
    final result = ref.read(importServiceProvider).parseBytes(
          bytes: picked.bytes,
          sourceId: 'file:${picked.name}',
        );
    await _handleParsed(context, result);
  }

  Future<void> importFromUrl(BuildContext context) async {
    final url = await showUrlDialog(context);
    if (url == null || url.isEmpty || !context.mounted) return;
    final result = await ref.read(subscriptionProvider.notifier).fetchAndParse(url);
    if (!context.mounted) return;
    final imported = await _handleParsed(context, result);
    if (imported) {
      await ref.read(subscriptionProvider.notifier).markActivated(url);
    }
  }

  /// Zeigt Vorschau, übernimmt Daten, fragt Berechtigung. Gibt `true` bei Erfolg zurück.
  Future<bool> _handleParsed(BuildContext context, Result<ParsedImport> result) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (result) {
      case Err(:final message):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.importFailed),
            content: Text(message),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
        );
        return false;
      case Ok(:final value):
        final current = ref.read(appDataProvider).value?.wasteTypes ?? const <WasteType>[];
        final byId = {for (final t in current) t.id: t};
        final resolved = [
          for (final name in value.distinctRawNames)
            byId[WasteTypeCatalog.normalizeId(name)] ?? WasteTypeCatalog.createDefault(name),
        ];
        final mode = await showImportPreviewDialog(context, value, resolved);
        if (mode == null) return false;
        final outcome = await ref.read(appDataProvider.notifier).applyParsedImport(value, mode);
        if (!context.mounted) return true;
        await ensureNotificationPermission(context, ref);
        messenger.showSnackBar(SnackBar(content: Text(l10n.importSuccess(outcome.imported))));
        return true;
    }
  }
}
```

In `lib/features/import/providers/subscription_provider.dart` die Methode `markActivated` ergänzen (speichert URL und Zeitpunkt, ohne erneut zu laden, weil der Import gerade über die Vorschau lief):

```dart
  Future<void> markActivated(String url) =>
      _commit(Subscription(url: url.trim(), lastFetched: ref.read(clockProvider).now()));
```

In `lib/app/app_shell.dart` den Home-Tab so verdrahten:

```dart
          Builder(
            key: const Key('tab-home'),
            builder: (context) {
              final flow = ImportFlow(ref);
              return UpcomingScreen(
                onImportFile: () => flow.importFromFile(context),
                onEnterUrl: () => flow.importFromUrl(context),
              );
            },
          ),
```

Das `children`-Array des `IndexedStack` darf dann nicht mehr `const` sein.

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/import test/app
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`. Hinweis: Beim ersten Durchlauf fehlen `ensureNotificationPermission` nach dem Snackbar-Zeitpunkt oder umgekehrt, wenn die Reihenfolge im Test nicht stimmt. Reihenfolge ist: Berechtigungsdialog zuerst, Snackbar danach.

- [ ] **Step 5: Im Emulator manuell prüfen**

```powershell
flutter run -d emulator-5554
```

Fixture-Datei per `adb push test/fixtures/augsburg_2026.csv /sdcard/Download/` auf den Emulator kopieren, „Datei importieren" tippen, Datei auswählen, Vorschau bestätigen, Berechtigung erteilen. Erwartet: Startseite zeigt nächste Abholung.

- [ ] **Step 6: Commit**

```powershell
git add lib test
git commit -m "Add import flow with preview, URL dialog and permission prompt`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---
### Task 18: Einstellungen – Erinnerungen

**Files:**
- Create: `lib/features/settings/ui/settings_screen.dart`, `lib/features/reminders/ui/reminders_section.dart`, `lib/features/reminders/ui/add_reminder_sheet.dart`, `lib/features/reminders/providers/permission_status_provider.dart`
- Modify: `lib/app/app_shell.dart` (Platzhalter „settings" durch `SettingsScreen` ersetzen)
- Test: `test/features/reminders/reminders_section_test.dart`

**Interfaces:**
- Consumes: `reminderRulesProvider`, `notificationGatewayProvider`, `ensureNotificationPermission`.
- Produces:
  - `class SettingsScreen extends ConsumerWidget` (ListView mit Abschnitten; Abschnitte für Abfuhrarten und Daten kommen in Task 19/20)
  - `class RemindersSection extends ConsumerWidget`
  - `Future<ReminderRule?> showAddReminderSheet(BuildContext context)`
  - `permissionStatusProvider: FutureProvider<NotificationPermission>`, `exactAlarmsProvider: FutureProvider<bool>`
  - `String formatRuleTime(ReminderRule rule)` → `'18:00'`

- [ ] **Step 1: Test schreiben**

`test/features/reminders/reminders_section_test.dart`:

```dart
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/reminders/ui/reminders_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

void main() {
  testWidgets('lists default rules, toggles and deletes, sends test notification', (tester) async {
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.granted;
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(settings: settings, gateway: gateway));

    expect(find.text('Am Vortag'), findsOneWidget);
    expect(find.text('um 18:00'), findsOneWidget);
    expect(find.text('Am Abholtag'), findsOneWidget);
    expect(find.text('um 07:00'), findsOneWidget);
    expect(find.text('Benachrichtigungen erlaubt'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(settings.rules![0].enabled, isFalse);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    expect(settings.rules!.length, 1);

    await tester.tap(find.text('Test-Benachrichtigung senden'));
    await tester.pumpAndSettle();
    expect(gateway.shown.single.$1, 'Test');
  });

  testWidgets('add reminder via sheet', (tester) async {
    final settings = InMemorySettingsRepository();
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(settings: settings));
    await tester.tap(find.text('Erinnerung hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwei Tage vorher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(settings.rules!.length, 3);
    expect(settings.rules!.last.daysBefore, 2);
  });

  testWidgets('shows request button when permission denied', (tester) async {
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.denied;
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(gateway: gateway));
    expect(find.text('Benachrichtigungen nicht erlaubt'), findsOneWidget);
    expect(find.text('Berechtigung anfragen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/reminders/reminders_section_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/reminders/providers/permission_status_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../domain/notification_gateway.dart';

final permissionStatusProvider = FutureProvider<NotificationPermission>(
  (ref) => ref.watch(notificationGatewayProvider).permissionStatus(),
);

final exactAlarmsProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationGatewayProvider).canScheduleExact(),
);
```

`lib/features/reminders/ui/add_reminder_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../data/models/reminder_rule.dart';
import '../../../l10n/app_localizations.dart';

String formatRuleTime(ReminderRule rule) =>
    '${rule.hour.toString().padLeft(2, '0')}:${rule.minute.toString().padLeft(2, '0')}';

String daysBeforeLabel(AppLocalizations l10n, int daysBefore) => switch (daysBefore) {
      0 => l10n.reminderDayOf,
      1 => l10n.reminderDayBefore,
      _ => l10n.reminderTwoDaysBefore,
    };

Future<ReminderRule?> showAddReminderSheet(BuildContext context) {
  return showModalBottomSheet<ReminderRule>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _AddReminderSheet(),
  );
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  int _daysBefore = 1;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addReminder, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final d in [0, 1, 2])
            RadioListTile<int>(
              value: d,
              groupValue: _daysBefore,
              title: Text(daysBeforeLabel(l10n, d)),
              onChanged: (v) => setState(() => _daysBefore = v!),
            ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.reminderAt(_time.format(context))),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              ReminderRule(
                id: ReminderRule.newId(),
                daysBefore: _daysBefore,
                hour: _time.hour,
                minute: _time.minute,
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
```

Hinweis: Falls `RadioListTile.groupValue` in Flutter 3.47 als deprecated markiert ist, stattdessen die Liste in eine `RadioGroup<int>(groupValue: _daysBefore, onChanged: ...)` einbetten und bei den Tiles `groupValue`/`onChanged` weglassen.

`lib/features/reminders/ui/reminders_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_gateway.dart';
import '../providers/permission_status_provider.dart';
import '../providers/reminder_rules_provider.dart';
import 'add_reminder_sheet.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = ref.watch(reminderRulesProvider).value ?? const <ReminderRule>[];
    final permission = ref.watch(permissionStatusProvider).value ?? NotificationPermission.unknown;
    final exact = ref.watch(exactAlarmsProvider).value ?? true;
    final notifier = ref.read(reminderRulesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.sectionReminders, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ),
        for (final rule in rules)
          ListTile(
            leading: Icon(rule.daysBefore == 0 ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined),
            title: Text(daysBeforeLabel(l10n, rule.daysBefore)),
            subtitle: Text(l10n.reminderAt(formatRuleTime(rule))),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: rule.hour, minute: rule.minute),
              );
              if (picked != null) {
                await notifier.update(rule.copyWith(hour: picked.hour, minute: picked.minute));
              }
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: rule.enabled, onChanged: (v) => notifier.update(rule.copyWith(enabled: v))),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => notifier.remove(rule.id),
                ),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(rules.length >= ReminderRule.maxRules ? l10n.maxRemindersReached : l10n.addReminder),
          enabled: rules.length < ReminderRule.maxRules,
          onTap: () async {
            final rule = await showAddReminderSheet(context);
            if (rule != null) await notifier.add(rule);
          },
        ),
        ListTile(
          leading: Icon(
            permission == NotificationPermission.granted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            color: permission == NotificationPermission.denied ? theme.colorScheme.error : null,
          ),
          title: Text(switch (permission) {
            NotificationPermission.granted => l10n.permissionGranted,
            NotificationPermission.denied => l10n.permissionDenied,
            NotificationPermission.unknown => l10n.permissionUnknown,
          }),
          subtitle: !exact ? Text(l10n.exactAlarmsMissing) : null,
          trailing: permission == NotificationPermission.granted
              ? null
              : TextButton(
                  onPressed: () async {
                    await ref.read(notificationGatewayProvider).requestPermission();
                    ref.invalidate(permissionStatusProvider);
                    ref.invalidate(exactAlarmsProvider);
                  },
                  child: Text(l10n.requestPermission),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.send_outlined),
          title: Text(l10n.sendTestNotification),
          onTap: () => ref.read(notificationGatewayProvider).showNow(
                title: l10n.testNotificationTitle,
                body: l10n.testNotificationBody,
              ),
        ),
      ],
    );
  }
}
```

`lib/features/settings/ui/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../reminders/ui/reminders_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          RemindersSection(),
          Divider(),
        ],
      ),
    );
  }
}
```

In `lib/app/app_shell.dart` den Platzhalter „settings" durch `const SettingsScreen(key: Key('tab-settings'))` ersetzen.

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/reminders test/app
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "Add settings screen with reminder rules section`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 19: Einstellungen – Abfuhrarten bearbeiten

**Files:**
- Create: `lib/features/waste_types/ui/waste_types_section.dart`, `lib/features/waste_types/ui/edit_waste_type_sheet.dart`
- Modify: `lib/features/settings/ui/settings_screen.dart` (Abschnitt einfügen)
- Test: `test/features/waste_types/waste_types_section_test.dart`

**Interfaces:**
- Consumes: `appDataProvider`, `WasteTypeCatalog.palette`, `WasteTypeCatalog.iconKeys`, `wasteIconFor`, `accentFor`.
- Produces: `class WasteTypesSection extends ConsumerWidget`, `Future<WasteType?> showEditWasteTypeSheet(BuildContext context, WasteType type)`

- [ ] **Step 1: Test schreiben**

`test/features/waste_types/waste_types_section_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/waste_types/ui/waste_types_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');

void main() {
  testWidgets('lists types, toggles notifications, edits name and color', (tester) async {
    final repo = InMemoryEventRepository(const AppData(events: [], wasteTypes: [bio]));
    await pumpApp(tester, const Scaffold(body: SingleChildScrollView(child: WasteTypesSection())),
        overrides: testOverrides(events: repo));

    expect(find.text('Biotonne'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes.single.notificationsEnabled, isFalse);

    await tester.tap(find.text('Biotonne'));
    await tester.pumpAndSettle();
    expect(find.text('Abfuhrart bearbeiten'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bio');
    await tester.tap(find.byKey(const Key('color-0xFF1E88E5')));
    await tester.tap(find.byKey(const Key('icon-paper')));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final saved = repo.data.wasteTypes.single;
    expect(saved.displayName, 'Bio');
    expect(saved.color, 0xFF1E88E5);
    expect(saved.icon, 'paper');
    expect(saved.id, 'bio');
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/waste_types/waste_types_section_test.dart
```

Erwartet: Compile-Fehler.

- [ ] **Step 3: Implementieren**

`lib/features/waste_types/ui/edit_waste_type_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/waste_type_catalog.dart';
import 'waste_icons.dart';

Future<WasteType?> showEditWasteTypeSheet(BuildContext context, WasteType type) {
  return showModalBottomSheet<WasteType>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EditSheet(type: type),
    ),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.type});
  final WasteType type;
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.type.displayName);
  late int _color = widget.type.color;
  late String _icon = widget.type.icon;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _hex(int c) => '0x${c.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editWasteType, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.name)),
          const SizedBox(height: 16),
          Text(l10n.color, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in WasteTypeCatalog.palette)
                InkWell(
                  key: Key('color-${_hex(c)}'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentFor(context, c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _color ? theme.colorScheme.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: c == _color ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.icon, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in WasteTypeCatalog.iconKeys)
                ChoiceChip(
                  key: Key('icon-$key'),
                  label: Icon(wasteIconFor(key), size: 20),
                  selected: key == _icon,
                  onSelected: (_) => setState(() => _icon = key),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim();
              Navigator.pop(
                context,
                widget.type.copyWith(
                  displayName: name.isEmpty ? widget.type.displayName : name,
                  color: _color,
                  icon: _icon,
                ),
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/waste_types/ui/waste_types_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import 'edit_waste_type_sheet.dart';
import 'waste_icons.dart';

class WasteTypesSection extends ConsumerWidget {
  const WasteTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final types = ref.watch(appDataProvider).value?.wasteTypes ?? const <WasteType>[];
    final notifier = ref.read(appDataProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.sectionWasteTypes, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ),
        for (final t in types)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accentFor(context, t.color).withValues(alpha: 0.18),
              child: Icon(wasteIconFor(t.icon), color: accentFor(context, t.color)),
            ),
            title: Text(t.displayName),
            subtitle: Text(l10n.notifyForType),
            trailing: Switch(
              value: t.notificationsEnabled,
              onChanged: (v) => notifier.updateWasteType(t.copyWith(notificationsEnabled: v)),
            ),
            onTap: () async {
              final edited = await showEditWasteTypeSheet(context, t);
              if (edited != null) await notifier.updateWasteType(edited);
            },
          ),
      ],
    );
  }
}
```

In `lib/features/settings/ui/settings_screen.dart` nach `RemindersSection()` und `Divider()` die Zeilen `WasteTypesSection(),` und `Divider(),` ergänzen (Import `../../waste_types/ui/waste_types_section.dart`).

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test test/features/waste_types test/app
flutter analyze
```

Erwartet: `All tests passed!`, `No issues found!`. Falls das Antippen des Farbkreises im Test „off-screen" meldet: `await tester.ensureVisible(find.byKey(...))` vor dem Tap.

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "Add waste type editing in settings`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 20: Einstellungen – Daten, URL-Abo, Über, Hinweis bei beschädigten Daten

**Files:**
- Create: `lib/features/settings/ui/data_section.dart`, `lib/features/settings/ui/about_section.dart`
- Modify: `lib/features/settings/ui/settings_screen.dart`, `lib/app/app_shell.dart` (Snackbar bei `wasCorruptOnLoad`)
- Test: `test/features/settings/data_section_test.dart`, `test/app/corrupt_notice_test.dart`

**Interfaces:**
- Consumes: `ImportFlow`, `subscriptionProvider`, `appDataProvider`, `package_info_plus`.
- Produces: `class DataSection extends ConsumerWidget`, `class AboutSection extends StatefulWidget`

- [ ] **Step 1: Tests schreiben**

`test/features/settings/data_section_test.dart`:

```dart
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/settings/ui/data_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

void main() {
  testWidgets('shows subscription state and removes it', (tester) async {
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: 'https://a.example/x.ics', lastFetched: DateTime(2026, 1, 1, 8), lastError: 'Status 500');
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(settings: settings));
    expect(find.text('https://a.example/x.ics'), findsOneWidget);
    expect(find.textContaining('Fehler: Status 500'), findsOneWidget);
    await tester.tap(find.text('Abo entfernen'));
    await tester.pumpAndSettle();
    expect(settings.subscription, isNull);
    expect(find.text('Kein Abo eingerichtet'), findsOneWidget);
  });

  testWidgets('delete all asks for confirmation and clears data', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
    ));
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: 'https://a.example/x.ics');
    final gateway = FakeNotificationGateway();
    await pumpApp(tester, const Scaffold(body: DataSection()),
        overrides: testOverrides(events: repo, settings: settings, gateway: gateway));
    await tester.tap(find.text('Alle Daten löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Wirklich alles löschen?'), findsOneWidget);
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(repo.data.events, isEmpty);
    expect(settings.subscription, isNull);
    expect(gateway.cancelAllCount, 1);
  });
}
```

`test/app/corrupt_notice_test.dart`:

```dart
import 'package:abfallkalender/app/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_repositories.dart';
import '../support/pump_app.dart';
import '../support/test_container.dart';

void main() {
  testWidgets('shows notice when stored data was corrupt', (tester) async {
    final repo = InMemoryEventRepository()..corruptOnLoad = true;
    await pumpApp(tester, const AppShell(), overrides: testOverrides(events: repo));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('beschädigt'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Fehlschlag bestätigen**

```powershell
flutter test test/features/settings test/app/corrupt_notice_test.dart
```

Erwartet: Compile-Fehler bzw. Test schlägt fehl.

- [ ] **Step 3: Implementieren**

`lib/features/settings/ui/data_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subscription.dart';
import '../../../l10n/app_localizations.dart';
import '../../import/providers/subscription_provider.dart';
import '../../import/ui/import_flow.dart';
import '../../upcoming/providers/app_data_provider.dart';

class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sub = ref.watch(subscriptionProvider).value;
    final flow = ImportFlow(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.sectionData, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: Text(l10n.importFile),
          onTap: () => flow.importFromFile(context),
        ),
        _SubscriptionTile(sub: sub, onEnterUrl: () => flow.importFromUrl(context)),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
          title: Text(l10n.deleteAllData, style: TextStyle(color: theme.colorScheme.error)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteAllConfirmTitle),
                content: Text(l10n.deleteAllConfirmBody),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await ref.read(subscriptionProvider.notifier).remove();
            await ref.read(appDataProvider.notifier).clearAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataDeleted)));
            }
          },
        ),
      ],
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  const _SubscriptionTile({required this.sub, required this.onEnterUrl});
  final Subscription? sub;
  final VoidCallback onEnterUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = sub;
    if (s == null) {
      return ListTile(
        leading: const Icon(Icons.link),
        title: Text(l10n.subscription),
        subtitle: Text(l10n.subscriptionNone),
        trailing: TextButton(onPressed: onEnterUrl, child: Text(l10n.enterUrl)),
      );
    }
    final fetched = s.lastFetched == null
        ? l10n.subscriptionNeverFetched
        : l10n.subscriptionLastFetched(DateFormat('d. MMM yyyy, HH:mm', 'de').format(s.lastFetched!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.link),
          title: Text(s.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fetched),
              if (s.lastError != null)
                Text(l10n.subscriptionError(s.lastError!), style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refreshNow),
                onPressed: () => ref.read(subscriptionProvider.notifier).refresh(force: true),
              ),
              TextButton(
                onPressed: () => ref.read(subscriptionProvider.notifier).remove(),
                child: Text(l10n.removeSubscription),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

`lib/features/settings/ui/about_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});
  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.sectionAbout, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ),
        ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.version(_version))),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(l10n.licenses),
          onTap: () => showLicensePage(context: context, applicationName: l10n.appTitle),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.privacyNote, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
```

`lib/features/settings/ui/settings_screen.dart` vollständig:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../reminders/ui/reminders_section.dart';
import '../../waste_types/ui/waste_types_section.dart';
import 'about_section.dart';
import 'data_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          RemindersSection(),
          Divider(),
          WasteTypesSection(),
          Divider(),
          DataSection(),
          Divider(),
          AboutSection(),
        ],
      ),
    );
  }
}
```

In `lib/app/app_shell.dart` in `_AppShellState.initState` den Microtask erweitern:

```dart
    Future.microtask(() async {
      await ref.read(appDataProvider.future);
      if (ref.read(appDataProvider.notifier).wasCorruptOnLoad && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).corruptDataNotice),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      await ref.read(lifecycleServiceProvider).onStart();
    });
```

Import `../features/upcoming/providers/app_data_provider.dart` ergänzen.

- [ ] **Step 4: Tests laufen lassen**

```powershell
flutter test
flutter analyze
```

Erwartet: Alle Tests grün, `No issues found!`. Hinweis zum `package_info_plus` im Widget-Test: `PackageInfo.fromPlatform()` wirft in Tests ohne Plattform-Kanal; der `catchError` fängt das ab und die Version bleibt leer.

- [ ] **Step 5: Emulator-Durchlauf**

```powershell
flutter run -d emulator-5554
```

Prüfen: Einstellungen zeigen alle vier Abschnitte, „Alle Daten löschen" fragt nach, „Test-Benachrichtigung senden" zeigt eine Benachrichtigung in der Statusleiste.

- [ ] **Step 6: Commit**

```powershell
git add lib test
git commit -m "Add data, subscription and about sections; corrupt data notice`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 21: CI, Release-Konfiguration, Codemagic

**Files:**
- Create: `.github/workflows/ci.yml`, `codemagic.yaml`, `android/key.properties.example`, `README.md`
- Modify: `android/app/build.gradle.kts` (Release-Signierung aus `key.properties`, falls vorhanden), `.gitignore` (`android/key.properties`, `*.jks`)

**Interfaces:**
- Produces: CI, die bei jedem Push `flutter analyze`, `flutter test` und `flutter build apk --release` ausführt; Codemagic-Workflow für iOS-Build; dokumentierter Signierungs-Ablauf.

- [ ] **Step 1: GitHub Actions**

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.47.6
          cache: true
      - run: flutter pub get
      - run: flutter gen-l10n
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 2: Android-Signierung vorbereiten**

`android/key.properties.example`:

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=upload
storeFile=../upload-keystore.jks
```

`.gitignore` ergänzen:

```
android/key.properties
*.jks
```

`android/app/build.gradle.kts`: Oben nach den `plugins { }`-Block einfügen:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Im `android { }`-Block vor `buildTypes`:

```kotlin
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
```

Keystore erzeugen (einmalig, lokal, nicht einchecken):

```powershell
& "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\keytool.exe" -genkey -v -keystore android\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android\key.properties.example android\key.properties
```

Dann `android\key.properties` mit den echten Passwörtern füllen.

- [ ] **Step 3: Codemagic**

`codemagic.yaml`:

```yaml
workflows:
  ios-testflight:
    name: iOS TestFlight
    instance_type: mac_mini_m2
    environment:
      flutter: 3.47.6
      xcode: latest
      groups:
        - app_store_credentials # APP_STORE_CONNECT_ISSUER_ID, _KEY_IDENTIFIER, _PRIVATE_KEY
      ios_signing:
        distribution_type: app_store
        bundle_identifier: de.abfallkalender.app
    scripts:
      - name: Pub get and l10n
        script: |
          flutter pub get
          flutter gen-l10n
      - name: Analyze and test
        script: |
          flutter analyze
          flutter test
      - name: Set up code signing
        script: xcode-project use-profiles
      - name: Build ipa
        script: flutter build ipa --release --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true

  android-release:
    name: Android Release
    instance_type: linux_x2
    environment:
      flutter: 3.47.6
      java: 17
      groups:
        - android_keystore # CM_KEYSTORE (base64), CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS, CM_KEY_PASSWORD
    scripts:
      - name: Restore keystore
        script: |
          echo $CM_KEYSTORE | base64 --decode > $CM_BUILD_DIR/android/upload-keystore.jks
          cat > $CM_BUILD_DIR/android/key.properties <<EOF
          storePassword=$CM_KEYSTORE_PASSWORD
          keyPassword=$CM_KEY_PASSWORD
          keyAlias=$CM_KEY_ALIAS
          storeFile=../upload-keystore.jks
          EOF
      - name: Build
        script: |
          flutter pub get
          flutter gen-l10n
          flutter test
          flutter build appbundle --release
    artifacts:
      - build/app/outputs/bundle/release/*.aab
```

iOS-Bundle-ID in Xcode-Projekt setzen: In `ios/Runner.xcodeproj/project.pbxproj` alle `PRODUCT_BUNDLE_IDENTIFIER = de.abfallkalender.abfallkalender;` durch `PRODUCT_BUNDLE_IDENTIFIER = de.abfallkalender.app;` ersetzen (drei Vorkommen für Debug/Release/Profile, die `RunnerTests`-Einträge unverändert lassen).

- [ ] **Step 4: README**

`README.md`:

```markdown
# Abfallkalender

Flutter-App für iOS und Android: Abfuhrtermine per CSV, ICS oder ICS-URL importieren, im Kalender sehen und per lokaler Benachrichtigung erinnert werden. Alle Daten bleiben auf dem Gerät.

## Entwicklung

- Flutter 3.47.x stable, JDK 17.
- `flutter pub get`, `flutter gen-l10n`, `flutter test`, `flutter run`.
- Design-Spec: `docs/superpowers/specs/2026-10-07-abfallkalender-app-design.md`.

## Release

- Android: `android/key.properties` nach Vorlage `key.properties.example` anlegen, dann `flutter build appbundle --release`.
- iOS: Codemagic-Workflow `ios-testflight` (siehe `codemagic.yaml`), benötigt App-Store-Connect-API-Key in der Umgebungsgruppe `app_store_credentials`.

## Testdaten

`test/fixtures/augsburg_2026.ics` und `.csv` (Landkreis Augsburg, 2026).
```

- [ ] **Step 5: Prüfen**

```powershell
flutter analyze
flutter test
flutter build apk --release
```

Erwartet: alles grün, `app-release.apk` gebaut (ohne `key.properties` mit Debug-Signatur). Mit `key.properties` zusätzlich `flutter build appbundle --release` prüfen.

- [ ] **Step 6: Commit**

```powershell
git add .github codemagic.yaml android/key.properties.example android/app/build.gradle.kts .gitignore README.md ios
git commit -m "Add CI, release signing setup and Codemagic workflows`n`nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Nach Abschluss

- Vollständiger Testlauf `flutter test`, `flutter analyze`.
- Manuelle Prüfung laut Spec Abschnitt 8: Import beider Fixtures auf dem Emulator, Test-Benachrichtigung, eine Erinnerung mit Uhrzeit „in 2 Minuten" anlegen und auf das Eintreffen warten (App dabei schließen), Emulator-Zeitzone in den Einstellungen umstellen und prüfen, dass die Uhrzeiten in der Liste stimmen.
- Store-Assets (Icon, Screenshots, Beschreibung, Datenschutzerklärung) sind ein separater Schritt nach diesem Plan.
