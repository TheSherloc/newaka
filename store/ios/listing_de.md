# App Store Connect: Produktseite Newaka (Deutsch)

Alle Felder in der Reihenfolge, in der App Store Connect sie abfragt. Zeichenlimits sind Apples Vorgaben.

## App-Informationen

| Feld | Wert |
|---|---|
| Name (30) | `Newaka` |
| Untertitel (30) | `Abfallkalender mit Erinnerung` |
| Bundle-ID | `de.newaka.app` |
| SKU | `newaka-ios` |
| Primäre Sprache | Deutsch |
| Primäre Kategorie | Dienstprogramme |
| Sekundäre Kategorie | Produktivität |
| Altersfreigabe | 4+ (keine der abgefragten Inhalte) |
| Preis | Kostenlos |
| Urheberrecht | `2026 Quentin Nohl` |

## Version 1.0

**Werbetext (170)**

```
Kalender der Stadt importieren, Erinnerung einstellen, fertig. Newaka meldet sich am Vorabend und am Abholtag.
```

**Beschreibung (4000)**

```
Newaka ist nur eine weitere Abfallkalender-App. Aber eine, die genau das macht, was sie soll: dich rechtzeitig daran erinnern, die richtige Tonne rauszustellen.

SO FUNKTIONIERT ES
Fast jede Stadt und jeder Landkreis bietet den Abfuhrkalender als ICS- oder CSV-Datei zum Download an. Diese Datei importierst du in Newaka, entweder einmalig oder als Abo per Link. Newaka erkennt die Abfuhrarten automatisch, legt ihnen Farbe und Symbol an und plant die Erinnerungen.

ERINNERUNGEN, DIE ANKOMMEN
Standardmäßig erinnert Newaka am Vorabend um 18 Uhr und am Abholtag um 7 Uhr. Beides kannst du anpassen, abschalten oder um weitere Zeiten ergänzen, bis zu fünf Regeln. Die Erinnerungen laufen über das System und kommen auch, wenn die App geschlossen ist.

DEIN KALENDER, DEINE ARTEN
Auf der Startseite siehst du sofort die nächste Abholung und alle Termine der kommenden vier Wochen. Der Monatskalender zeigt alle Abfuhrtage mit farbigen Markierungen. Abfuhrarten, die dich nicht betreffen, blendest du aus oder löschst sie.

ABO PER LINK
Hinterlegst du den Link zum Kalender deiner Kommune, holt Newaka Änderungen automatisch nach und plant die Erinnerungen neu.

KEIN KONTO, KEINE DATENSAMMLUNG
Newaka braucht keine Registrierung. Alle Daten bleiben auf deinem Gerät. Die App enthält keine Werbung, kein Tracking und keine In-App-Käufe.

Noch keine Datei zur Hand? Mit den Beispieldaten schaust du dir die App in Ruhe an.
```

**Schlüsselwörter (100, kommagetrennt, ohne Leerzeichen)**

```
abfallkalender,müllkalender,abfuhrkalender,müll,erinnerung,biotonne,restmüll,gelber sack,papier,tonne
```

**Support-URL**

```
https://github.com/TheSherloc/newaka/issues
```


**Marketing-URL (optional)**

Leer lassen.

**Datenschutzrichtlinien-URL**

```
https://thesherloc.github.io/newaka/datenschutz.html
```

Voraussetzung: GitHub Pages im Mirror-Repo aktivieren (Settings → Pages → Source: Deploy from a branch → Branch `master`, Ordner `/docs`). Die Seite liegt im Repo unter `docs/datenschutz.html`.

**Hinweise zur Überprüfung (für das Review-Team)**

```
Die App benötigt kein Konto. Zum Testen in der App: Einstellungen → Daten → "Beispieldaten laden". Das importiert einen fiktiven Abfuhrkalender für zwölf Monate. Erinnerungen lassen sich unter Einstellungen → Erinnerungen → "Test-Benachrichtigung senden" sofort auslösen.
```

**Versionstext "Neue Funktionen" (4000)**

```
Erste Version.
```

## Screenshots

Erzeugt mit `flutter test test/tool/render_store_screenshots_test.dart`, Ablage unter `store/ios/screenshots/`:

| Ordner | Displayklasse | Pixel | Pflicht |
|---|---|---|---|
| `6.9` | iPhone 6,9" (16 Pro Max u. a.) | 1320 × 2868 | ja |
| `6.7` | iPhone 6,7" (14 Plus, 15 Plus u. a.) | 1290 × 2796 | optional, wird sonst skaliert |

Reihenfolge beim Hochladen: `01-start`, `02-termine`, `03-kalender`, `04-erinnerungen`, `05-import`. iPad-Screenshots sind nicht nötig, solange die App unter "Geräte" nur iPhone unterstützt (siehe Xcode: Targeted Device Families = iPhone).

## App-Datenschutz (Fragebogen "Datenschutz-Details")

| Frage | Antwort |
|---|---|
| Erfasst diese App Daten? | **Nein, wir erfassen keine Daten von dieser App.** |

Begründung: Newaka speichert Termine, Abfuhrarten und Einstellungen ausschließlich lokal. Beim URL-Abo lädt die App die vom Nutzer eingetragene Adresse direkt; es gibt keinen eigenen Server, kein Analytics-SDK, keine Werbung.

## Export-Compliance

Beantwortet durch `ITSAppUsesNonExemptEncryption = false` in der Info.plist. Falls doch gefragt wird: "Keinen der oben genannten Algorithmen" (nur HTTPS über Systembibliotheken).

## Vor der Einreichung prüfen

- [ ] GitHub Pages aktiviert, Datenschutz-URL öffnet sich im Browser
- [ ] Support-URL öffentlich erreichbar
- [ ] Screenshots 6,9" hochgeladen, Reihenfolge wie oben
- [ ] TestFlight-Build der Version 1.0 (Build-Nummer aus Codemagic) ausgewählt
- [ ] Altersfreigabe-Fragebogen ausgefüllt (alles "Nein")
- [ ] Datenschutz-Details beantwortet ("Keine Daten erfasst")
