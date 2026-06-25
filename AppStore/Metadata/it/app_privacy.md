Nutrition labels coerenti con `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` vuoto, `NSPrivacyTracking = false`).

# Tracking

- Tracking: **No**.
- Pubblicità di terze parti: No.
- Data broker / cross-app tracking: No.
- Domini di tracking (`NSPrivacyTrackingDomains`): nessuno.

# Data Collection

Per la build attuale: **Data Not Collected**.

Tutti i dati che l'app legge/scrive restano sul dispositivo dell'utente o sono
gestiti da servizi Apple (WeatherKit, HealthKit, Game Center). Solea non
trasmette dati personali a server propri o di terze parti.

Dettaglio per tipologia che Apple potrebbe far comparire nel questionario:

- **Location**: usata in-app solo per chiamare WeatherKit di Apple per UV index
  e meteo. Apple gestisce la richiesta come servizio di sistema; Solea non
  registra né trasmette la posizione altrove. → *Non raccolta da Solea.*
- **Health & Fitness**: Solea **scrive** opzionalmente Time in Daylight (HKQuantityTypeIdentifierAppleStandHour-style metric)
  nel HealthKit dell'utente quando l'utente lo autorizza. Non legge alcun dato
  HealthKit. I dati restano nel Health store dell'utente. → *Non raccolta da Solea.*
- **Photos**: il diario fotografico salva le immagini scelte dall'utente in
  SwiftData locale (app sandbox). Nessun upload a Solea o terzi. → *Non raccolta da Solea.*
- **Game Center**: classifiche/achievement sono gestiti da Apple via GameKit; i
  dati di Game Center sono coperti dalla privacy policy di Apple, non da Solea. →
  *Non raccolta da Solea.*
- **Identifiers**: l'ID anonimo di dispositivo (UUID generato e salvato in
  UserDefaults, motivazione `CA92.1`/`1C8F.1` nel manifest) viene usato solo per
  rate-limit lato proxy **se** il proxy del coach è configurato. Nella build
  spedita `SOLEA_COACH_PROXY_URL` è vuoto → nessun id esce dal dispositivo.

# Critical Alerts

Dichiarate in `critical_alerts.md`: usate solo per gli stop-alert UV durante una
sessione (suono che bypassa Silenziato). Nessun upload di dati associato.

# In caso si abiliti il proxy del coach (futuro)

Se in una release futura `SOLEA_COACH_PROXY_URL` sarà valorizzato (es. Solea
Plus con risposte server), aggiornare nutrition labels e manifest aggiungendo:

- *Identifiers → Device ID* (linked / non-tracking, scopo App Functionality).
- *User Content → Other User Content* (testo dei messaggi al coach, linked /
  non-tracking, scopo App Functionality).
- `NSPrivacyCollectedDataTypes` corrispondenti in `App/PrivacyInfo.xcprivacy`.
