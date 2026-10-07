# Abfallkalender App – Design-Spezifikation

Datum: 2026-10-07
Status: Entwurf zur Prüfung

## 1. Ziel und Rahmen

Eine Flutter-App für iOS und Android, die in App Store und Play Store veröffentlicht wird. Nutzer importieren die Abfuhrtermine ihres Landkreises per CSV-Datei, ICS-Datei oder ICS-URL und werden zuverlässig vor jeder Abholung erinnert.

**Erfolgskriterien**

- Die beiden vorliegenden Beispieldateien (CSV in Windows-1252 mit `;`, ICS in UTF-8 vom Landkreis Augsburg, 94 Termine, 5 Abfuhrarten) importieren fehlerfrei.
- Erinnerungen erscheinen auch dann, wenn die App mehrere Wochen nicht geöffnet wurde.
- Die Oberfläche wirkt modern, ruhig und ist ohne Anleitung bedienbar.

**Festlegungen**

- Entwicklung auf Windows. Android-Builds lokal, iOS-Builds über Cloud-CI (Codemagic oder GitHub Actions mit macOS-Runner).
- Eine Adresse pro Installation.
- Lokal geplante Benachrichtigungen, kein Backend, kein Firebase.
- Keine Nutzerkonten, keine Cloud-Synchronisation, keine Werbung.
- Primäre UI-Sprache Deutsch. Lokalisierung ist über ARB-Dateien vorbereitet, Englisch ist in Version 1 nicht Pflicht.

**Nicht Teil von Version 1**

- Mehrere Adressen oder Haushalte.
- Home-Screen-Widgets.
- Automatische Suche nach dem passenden Landkreis-Kalender.
- Export der Termine.

## 2. Architektur

Ein Flutter-Projekt `abfallkalender`, feature-orientiert, drei Schichten pro Feature: `domain/` (reine Dart-Logik ohne Flutter-Import), `providers/` (Riverpod), `ui/`.

```
lib/
  main.dart                    # App-Start, ProviderScope, Theme
  app/                         # Shell mit Bottom-Navigation, Theme, Lokalisierung
  core/                        # Result-Typ, Datums-Helfer, Logger
  features/
    import/                    # CSV-/ICS-Parser, Encoding-Erkennung, URL-Abo, Import-UI
    calendar/                  # Monatsansicht, Tagesdetail
    upcoming/                  # Startseite: nächste Abholung + Liste, Onboarding-Zustand
    reminders/                 # ReminderRules, ReminderScheduler, NotificationGateway
    waste_types/               # Erkennung, Standardfarben, Icons, Bearbeitung
    settings/                  # Einstellungsseite, Daten löschen, Über
  data/
    models/                    # PickupEvent, WasteType, ReminderRule, Subscription
    repositories/              # EventRepository, SettingsRepository (Interface + JSON/Prefs-Impl)
```

**Abhängigkeiten** (bewusst knapp, keine Code-Generierung):
`flutter_riverpod`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `table_calendar`, `file_picker`, `http`, `shared_preferences`, `path_provider`, `intl`, `flutter_localizations`.

**Grundsätze**

- Parser, Merge-Logik und Scheduler sind reine Dart-Klassen. Plattform-Plugins werden nur über schmale Interfaces (`NotificationGateway`, `FileSource`, `HttpSource`, `Clock`) angesprochen, sodass alles mit Fakes testbar ist.
- Fehler werden als `Result<T>` (Erfolg mit Wert und Warnungen, oder Fehler mit Nutzertext) zurückgegeben. Keine Exceptions bis in die UI.
- Riverpod-Provider halten den Zustand; die UI ist zustandslos bis auf lokale Eingaben.

## 3. Datenmodell

### PickupEvent

| Feld | Typ | Beschreibung |
|---|---|---|
| `date` | Datum ohne Uhrzeit | Abholtag |
| `wasteTypeId` | String | Verweis auf WasteType |
| `sourceId` | String | `file:<name>` oder `url:<host>` |
| `note` | String? | Hinweistext aus ICS-DESCRIPTION, falls vorhanden |

Schlüssel: `date + wasteTypeId`. Erneute Importe erzeugen keine Duplikate.

### WasteType

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | String | Normalisierter Schlüssel, z. B. `biotonne` |
| `displayName` | String | Vom Nutzer änderbar |
| `color` | int (ARGB) | Akzentfarbe |
| `icon` | String | Schlüssel aus einem festen Icon-Set |
| `notificationsEnabled` | bool | Standard `true` |

**Normalisierung** des Rohnamens: Präfix "Abfuhr:" entfernen, trimmen, Kleinschreibung, Umlaute transliterieren, Nicht-Alphanumerisches zu `_`. Beispiele: "Abfuhr: Biotonne" wird `biotonne`, "Restmüll Tonne" wird `restmuell_tonne`, "Wertstofftonne / Gelber Container" wird `wertstofftonne_gelber_container`.

**Standardzuordnung** über Schlüsselwörter im normalisierten Namen, erste Übereinstimmung gewinnt:

| Schlüsselwort | Farbe | Icon |
|---|---|---|
| `bio` | Braun `#6D4C41` | Blatt |
| `rest`, `hausmuell` | Dunkelgrau `#455A64` | Mülltonne |
| `wertstoff`, `gelb`, `verpackung`, `plastik` | Gelb `#F9A825` | Recycling |
| `papier`, `karton` | Blau `#1E88E5` | Papier |
| `problem`, `schadstoff`, `sonder` | Rot `#D32F2F` | Warnung |
| `glas` | Grün `#2E7D32` | Flasche |
| `sperr` | Violett `#6A1B9A` | Sofa |
| sonst | Neutralgrau `#78909C` | Mülltonne |

### ReminderRule

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | String | UUID |
| `daysBefore` | int | 0 = Abholtag, 1 = Vortag, 2 = zwei Tage vorher |
| `time` | Stunde, Minute | Lokale Uhrzeit |
| `enabled` | bool | |

Standard nach Erstinstallation: Vortag 18:00 und Abholtag 07:00. Maximal 5 Regeln.

### Subscription

| Feld | Typ | Beschreibung |
|---|---|---|
| `url` | String | ICS-URL |
| `lastFetched` | DateTime? | |
| `lastError` | String? | Letzter Fehlertext für die Anzeige |

Höchstens eine Subscription.

### Persistenz

- Events und WasteTypes: eine JSON-Datei `data.json` im App-Dokumentenverzeichnis, atomar geschrieben (temporäre Datei, dann Umbenennen). Enthält `schemaVersion` für spätere Migrationen.
- ReminderRules, Subscription, Flags (Onboarding gesehen, letzter Scheduler-Lauf): SharedPreferences als JSON-Strings.
- Beides hinter `EventRepository` und `SettingsRepository`. Ein späterer Wechsel auf SQLite betrifft nur die Implementierungen.

## 4. UI und Design

Material 3, eigene Farbpalette, hell und dunkel nach Systemeinstellung, Systemschriftart. Bottom-Navigation mit drei Tabs.

### Tab "Start"

- Oben eine große Karte "Nächste Abholung": Icon und Akzentstreifen der Abfuhrart, Name, relative und absolute Datumsangabe ("Morgen, Donnerstag 9. Okt."), Hinweistext aus `note`, falls vorhanden ("Tonne bis 6:30 Uhr bereitstellen").
- Darunter die Termine der nächsten vier Wochen, nach Tag gruppiert, mit relativen Angaben ("Heute", "Morgen", "in 5 Tagen", danach Wochentag und Datum). Mehrere Abfuhrarten am selben Tag erscheinen in einer Karte als Chips.
- Leerzustand (keine Termine): Kurze Erklärung in zwei Sätzen und zwei große Buttons "Datei importieren" und "URL eintragen".

### Tab "Kalender"

- Monatsansicht (`table_calendar`), Wochenbeginn Montag, farbige Punkte pro Abfuhrart am Tag, maximal vier Punkte.
- Tippen auf einen Tag zeigt darunter die Termine des Tages. Wischen wechselt den Monat, ein "Heute"-Button springt zurück.
- Legende aller Abfuhrarten unter dem Kalender.

### Tab "Einstellungen"

- **Erinnerungen**: Liste der Regeln mit Schalter und Uhrzeit, Regel hinzufügen und löschen, Button "Test-Benachrichtigung senden", Anzeige des Berechtigungsstatus mit Link in die Systemeinstellungen.
- **Abfuhrarten**: Liste mit Name, Farbe, Icon, Schalter "Erinnern". Bearbeiten über ein Bottom-Sheet mit Farbwahl aus einer festen Palette und Icon-Wahl.
- **Daten**: "Datei importieren", "URL-Abo" (eintragen, jetzt aktualisieren, entfernen, letzter Abruf und letzter Fehler), "Alle Daten löschen" mit Bestätigung.
- **Über**: Version, Lizenzen, Datenschutzhinweis (alle Daten bleiben auf dem Gerät).

### Visuelle Richtung

Ruhig und klar. Jede Abfuhrart hat eine kräftige Akzentfarbe als Streifen am Kartenrand und als Punkt im Kalender. Große Berührungsflächen (mindestens 48 dp), Schriftgrößen folgen der Systemskalierung, Farbkontraste erfüllen WCAG AA in beiden Themes. Bio-Braun wird im Dark Theme leicht aufgehellt, damit der Kontrast stimmt.

### Berechtigungen

Die Notification-Berechtigung wird erst nach dem ersten erfolgreichen Import angefragt, mit einem erklärenden Dialog davor. Auf Android 13+ wird `POST_NOTIFICATIONS` angefragt, auf Android 12+ zusätzlich `SCHEDULE_EXACT_ALARM` mit Fallback auf ungefähre Alarme.

## 5. Import

### Ablauf

1. Nutzer wählt Datei (`file_picker`, Filter `ics`, `csv`, aber alle Dateien erlaubt) oder trägt URL ein.
2. Bytes werden dekodiert: erst UTF-8 strikt, bei Fehler Windows-1252 (über Latin-1 mit Korrektur der 0x80–0x9F-Zeichen).
3. Format wird am Inhalt erkannt: enthält `BEGIN:VCALENDAR`, dann ICS, sonst CSV.
4. Parser liefert `Result<ParsedImport>` mit Events (Rohname, Datum, Note) und Warnungen.
5. Abfuhrarten werden normalisiert und, falls neu, mit Standardfarbe und Icon angelegt. Bestehende WasteTypes behalten Nutzeränderungen.
6. Vorschau-Dialog: Anzahl Termine, Zeitraum, erkannte Abfuhrarten mit Farbe, Warnungen. Auswahl "Zusammenführen" (Standard) oder "Bestehende ersetzen".
7. Speichern, Scheduler neu laufen lassen, Erfolgsmeldung.

### ICS-Parser

- Zeilenfaltung auflösen (Folgezeile beginnt mit Leerzeichen oder Tab).
- Nur `VEVENT`-Blöcke. Gelesen: `DTSTART` (Formen `YYYYMMDD`, `YYYYMMDDTHHMMSS`, mit optionalem `Z` oder `;TZID=`), `SUMMARY`, `DESCRIPTION`. Datum wird als lokales Datum übernommen, Uhrzeit verworfen.
- Escapes in Texten auflösen (`\,`, `\;`, `\n`, `\\`).
- `SUMMARY`-Präfix "Abfuhr:" und ähnliche Präfixe vor einem Doppelpunkt entfernen, wenn der Rest nicht leer ist.
- Events ohne `DTSTART` oder `SUMMARY` werden übersprungen und als Warnung gezählt.

### CSV-Parser

- Trennzeichen: Häufigstes Zeichen aus `;`, `,`, Tabulator in der Kopfzeile.
- Anführungszeichen nach RFC 4180 (doppelte Quotes als Escape).
- Spaltenerkennung an der Kopfzeile: Datumsspalte heißt `datum` oder `date` (ohne Groß-/Kleinschreibung), sonst erste Spalte, deren Werte zu `dd.MM.yyyy` oder `yyyy-MM-dd` passen. Abfuhrart-Spalte heißt `abfuhrart`, `abfallart`, `art`, `typ`, `type` oder `fraktion`, sonst erste Textspalte, die weder Datum noch Wochentag ist.
- Fehlt eine Kopfzeile (erste Zeile enthält ein Datum), gelten die Heuristiken auf allen Zeilen.
- Zeilen ohne gültiges Datum werden übersprungen und als Warnung gezählt. Finden sich gar keine Events, ist das Ergebnis ein Fehler mit Erklärung.

### Merge-Logik

- Zusammenführen: Neue Events werden hinzugefügt, bestehende mit gleichem Schlüssel bleiben. Events aus derselben `sourceId`, die im neuen Import fehlen, werden entfernt (damit ein aktualisierter Jahreskalender Streichungen abbildet).
- Ersetzen: Alle Events werden gelöscht, WasteTypes bleiben erhalten.

### URL-Abo

- Dieselbe ICS-Pipeline über HTTP GET, Timeout 20 Sekunden, nur `http` und `https`.
- Automatische Aktualisierung beim App-Start und beim Zurückkehren in den Vordergrund, wenn `lastFetched` älter als 24 Stunden ist. Läuft im Hintergrund der UI, ohne Vorschau, Modus "Zusammenführen".
- Bei Fehler bleiben bestehende Daten unverändert, `lastError` wird gesetzt und in den Einstellungen gezeigt. Keine Fehler-Popups beim automatischen Abruf.

## 6. Benachrichtigungen

### ReminderScheduler (reines Dart)

Eingabe: Events, WasteTypes, ReminderRules, Jetzt-Zeitpunkt, Plattform-Limit.
Ausgabe: Liste geplanter Benachrichtigungen `(id, Zeitpunkt, Titel, Text)`.

- Nur Events mit `notificationsEnabled` auf ihrer WasteType und nur aktivierte Regeln.
- Pro Tag und Regel genau eine Benachrichtigung; mehrere Abfuhrarten werden zusammengefasst: Titel "Morgen Abholung", Text "Biotonne und Altpapier Tonne". Für `daysBefore = 0`: Titel "Heute Abholung". Für 2: "Übermorgen Abholung".
- Zeitpunkte in der Vergangenheit werden verworfen.
- Sortiert nach Zeitpunkt, auf das Limit gekürzt.
- ID ist deterministisch aus `date + daysBefore` (Hash auf 31 Bit), damit Neuplanung idempotent ist.

### Rollierendes Fenster

- iOS: maximal 60 Erinnerungen plus eine Hinweis-Benachrichtigung "Bitte Abfallkalender öffnen, damit die Erinnerungen aktuell bleiben", geplant einen Tag nach der letzten Erinnerung im Fenster.
- Android: maximal 200 Erinnerungen, keine Hinweis-Benachrichtigung.
- Neuplanung: alle anstehenden Benachrichtigungen der App absagen, dann das Fenster neu setzen.

### Auslöser für Neuplanung

- App-Start.
- Nach Import oder Subscription-Aktualisierung.
- Nach Änderung an ReminderRules oder WasteTypes.
- Rückkehr in den Vordergrund, wenn der letzte Lauf länger als 12 Stunden her ist.

### NotificationGateway

Interface mit `requestPermission()`, `permissionStatus()`, `cancelAll()`, `schedule(list)`, `showNow(title, text)`. Implementierung über `flutter_local_notifications` mit `zonedSchedule`, Zeitzone einmalig per `flutter_timezone` gelesen. Android-Kanal "Abfuhr-Erinnerungen" mit hoher Priorität. Bei fehlender Berechtigung für exakte Alarme wird `AndroidScheduleMode.inexactAllowWhileIdle` verwendet.

## 7. Fehlerbehandlung

- Alle Nutzertexte für Fehler sind konkret: "Die Datei enthält keine erkennbaren Termine. Erwartet wird eine Spalte mit Datum und eine mit der Abfuhrart." statt "Import fehlgeschlagen".
- Warnungen werden in der Vorschau gezeigt, blockieren den Import aber nicht.
- Beschädigte `data.json` wird beim Laden erkannt, unter `data.json.broken` gesichert, die App startet leer und zeigt einen Hinweis.
- Fehlende Berechtigungen werden in den Einstellungen dauerhaft sichtbar gemacht, nicht nur einmalig.

## 8. Tests

- **Unit-Tests** (reines Dart): ICS-Parser, CSV-Parser, Encoding-Erkennung, Namens-Normalisierung und Standardzuordnung, Merge-Logik, ReminderScheduler (Zusammenfassung, Limit, Vergangenheit, Idempotenz der IDs), Repositories mit temporärem Verzeichnis. Die beiden Beispieldateien liegen als Fixtures unter `test/fixtures/`.
- **Widget-Tests**: Startseite leer und mit Daten, Kalender mit Punkten und Tagesauswahl, Erinnerungsliste mit Umschalten.
- **Manuelle Prüfung** vor Release: Import beider Dateien auf einem Android-Gerät, Test-Benachrichtigung, geplante Erinnerung über Nacht, Zeitzonenwechsel im Emulator.

## 9. Build und Veröffentlichung

- GitHub Actions: `flutter analyze`, `flutter test`, `flutter build apk --release` bei jedem Push.
- iOS: Codemagic-Workflow für `flutter build ipa` und Upload zu TestFlight, sobald Apple-Developer-Konto und Zertifikate vorliegen. Die Projektkonfiguration (Bundle-ID, Berechtigungstexte in `Info.plist`, Android-Manifest-Rechte) wird im Plan als eigene Aufgabe angelegt.
- Store-Assets (Icon, Screenshots, Beschreibung, Datenschutzerklärung) sind ein separater Arbeitsschritt nach der funktionalen Fertigstellung.
