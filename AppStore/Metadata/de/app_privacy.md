Nutrition Labels in Übereinstimmung mit `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` leer, `NSPrivacyTracking = false`).

# Tracking

- Tracking: **Nein**.
- Werbung Dritter: Nein.
- Data Broker / App-übergreifendes Tracking: Nein.
- Tracking-Domains (`NSPrivacyTrackingDomains`): keine.

# Datenerhebung

Für den aktuellen Build: **Data Not Collected**.

Alle Daten, die die App liest oder schreibt, verbleiben auf dem Gerät des
Nutzers oder werden von Apple-Diensten verwaltet (WeatherKit, HealthKit,
Game Center). Solea überträgt keine personenbezogenen Daten an eigene Server
oder Dritte.

Details pro Kategorie, die App Store Connect im Fragebogen ausspielen könnte:

- **Location**: in der App nur für den Aufruf von Apples WeatherKit (UV-Index
  und Wetter) verwendet. Apple verarbeitet die Anfrage als Systemdienst; Solea
  protokolliert oder überträgt den Standort nicht weiter.
  → *Nicht von Solea erhoben.*
- **Health & Fitness**: Solea **schreibt** Time in Daylight in den HealthKit
  des Nutzers, sofern explizit autorisiert. HealthKit-Daten werden nicht
  gelesen. Werte verbleiben im Health-Speicher des Nutzers.
  → *Nicht von Solea erhoben.*
- **Photos**: Das Foto-Tagebuch speichert die vom Nutzer ausgewählten Bilder
  im lokalen SwiftData (App-Sandbox). Kein Upload an Solea oder Dritte.
  → *Nicht von Solea erhoben.*
- **Game Center**: Bestenlisten und Erfolge werden von Apple via GameKit
  verwaltet; Game-Center-Daten unterliegen Apples Datenschutzerklärung, nicht
  der von Solea. → *Nicht von Solea erhoben.*
- **Identifiers**: Eine anonyme Geräte-UUID (in UserDefaults gespeichert,
  Gründe `CA92.1` / `1C8F.1` im Manifest) wird nur zum Rate-Limit am
  Coach-Proxy verwendet, **wenn** der Proxy konfiguriert ist. Im
  ausgelieferten Build ist `SOLEA_COACH_PROXY_URL` leer → kein Identifier
  verlässt das Gerät.

# Critical Alerts

In `critical_alerts.md` deklariert: nur für UV-Stop-Alerts während einer
Sitzung verwendet (Ton, der den Lautlos-Modus umgeht). Keine Datenübertragung
verbunden.

# Falls der Coach-Proxy künftig aktiviert wird

Sollte eine künftige Version `SOLEA_COACH_PROXY_URL` setzen (z. B. Solea Plus
mit serverseitigen Antworten), Nutrition Labels und Manifest entsprechend
aktualisieren:

- *Identifiers → Device ID* (linked / kein Tracking, Zweck App Functionality).
- *User Content → Other User Content* (Text der Coach-Nachrichten, linked /
  kein Tracking, Zweck App Functionality).
- Entsprechende `NSPrivacyCollectedDataTypes`-Einträge in
  `App/PrivacyInfo.xcprivacy`.
