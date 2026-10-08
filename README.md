# Newaka – Nur eine weitere Abfallkalender-App

Newaka ist eine Flutter-App für iOS und Android: Abfuhrtermine per CSV, ICS oder ICS-URL importieren, im Kalender sehen und per lokaler Benachrichtigung erinnert werden. Alle Daten bleiben auf dem Gerät.

## Entwicklung

- Flutter 3.47.x stable, JDK 17.
- `flutter pub get`, `flutter gen-l10n`, `flutter test`, `flutter run`.

## Release

- Android: `android/key.properties` nach Vorlage `key.properties.example` anlegen, dann `flutter build appbundle --release`.
- iOS: Codemagic-Workflow `ios-testflight` (siehe `codemagic.yaml`), Voraussetzungen in Codemagic: App-Store-Connect-Team-Schlüssel (Rolle Admin) als Integration `newaka` unter Teams → Integrations → Developer Portal; darauf aufbauend unter Teams → Code signing identities ein Apple-Distribution-Zertifikat `newaka` und ein App-Store-Profil `newaka_app_store` für `de.newaka.app`.
- Store-Assets: `store/ios/listing_de.md` (alle Texte und Antworten für App Store Connect), Screenshots per `flutter test test/tool/render_store_screenshots_test.dart` nach `store/ios/screenshots/`, Datenschutzerklärung unter `docs/datenschutz.html`.

## Testdaten

`test/fixtures/augsburg_2026.ics` und `.csv` (Landkreis Augsburg, 2026).
