# App Store Connect submission checklist

Checklist aggiornata al 21 giugno 2026 per preparare Solea alla prima submission.
Per la sequenza operativa completa, dall'account Apple fino a `Submit for
Review`, usa `docs/APP_STORE_UPLOAD_RUNBOOK.md`.

## Stato locale

- Xcode richiesto: Xcode 26 o successivo, per compilare con iOS/watchOS SDK 26+.
- Versione app: `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 1`.
- Bundle ID:
  - iOS: `com.davidecapurro.Solea`
  - Widget extension: `com.davidecapurro.Solea.Widgets`
  - Watch app: `com.davidecapurro.Solea.watchkitapp`
- App Group: `group.com.davidecapurro.solea`.
- Privacy manifest presenti per app, widget e Watch app.
- Screenshot minimi App Store presenti e validati:
  - `AppStore/Screenshots/iPhone-6.9/01-solea-check.png`
  - `AppStore/Screenshots/iPhone-6.9/02-live-session.png`
  - `AppStore/Screenshots/iPhone-6.9/03-safety-reminders.png`
  - `AppStore/Screenshots/iPhone-6.9/04-session-plan.png`
  - `AppStore/Screenshots/iPhone-6.9/05-progress-diary.png`
  - `AppStore/Screenshots/iPhone-6.9/06-vacation-planner.png`
  - stessi nomi in `AppStore/Screenshots/iPhone-6.5/` se App Store Connect richiede il riquadro 6,5"
  - `AppStore/Screenshots/Apple-Watch/01-uv.png`
- Icona app: da inserire in `App/Resources/Assets.xcassets/AppIcon.appiconset` prima dell'upload.
  Usa `scripts/install-app-icon.sh <path-to-1024-png>` quando il PNG finale e' pronto.
- Export options upload: `AppStore/ExportOptions-AppStoreConnect.plist`.
- Metadata draft validabile con `scripts/validate-app-store-metadata.sh`.
- Metadata esportabile in file plain-text con `scripts/export-app-store-metadata.sh`.
- ID Game Center validabili con `scripts/validate-game-center-config.sh`.
- Campi esterni App Store Connect tracciati in `docs/APP_STORE_EXTERNAL_FIELDS.md` e validabili con `scripts/validate-app-store-external-fields.sh --strict`.
- Report compatto readiness: `scripts/app-store-readiness-report.sh`.
- Preparazione finale repo-side: `scripts/prepare-app-store-package.sh`.
- Archive/upload CLI opzionale: `scripts/archive-app-store.sh`.
- Gate finale locale disponibile con `scripts/app-store-final-check.sh`.
- Preflight locale: `scripts/app-store-preflight.sh` deve passare senza `--skip-icon-check` prima dell'archivio finale.

## Apple Developer Portal

Configura gli App ID espliciti con lo stesso bundle ID usato nel progetto.

- `com.davidecapurro.Solea`: WeatherKit, HealthKit, Game Center, App Groups, Push Notifications.
- `com.davidecapurro.Solea.Widgets`: App Groups.
- `com.davidecapurro.Solea.watchkitapp`: WeatherKit.
- App Group: crea/abilita `group.com.davidecapurro.solea` e associalo ad app iOS e widget.

## Game Center

Leaderboard da creare in App Store Connect:

- `solea.weekly.smart.minutes`
- `solea.longest.streak`

Achievement da creare in App Store Connect con gli stessi ID usati da `Badge.rawValue`:

- `firstSession`
- `weekStreak`
- `plannerCompleted`
- `vitaminD10k`

Scheda operativa con nomi e descrizioni: `docs/GAME_CENTER_SETUP.md`.

## Critical Alerts — non usati

Solea **non** usa Critical Alerts e **non** richiede l'entitlement
`com.apple.developer.usernotifications.critical-alerts`. Lo stop di sicurezza e
tutti i promemoria sono notifiche locali standard (`[.alert, .sound]`,
`UNNotificationSound.default`). Nessun gate di approvazione Apple da attendere e
nessun rischio di rifiuto legato a Critical Alerts.

## App Store Connect

- Crea o aggiorna l'app con bundle ID `com.davidecapurro.Solea`.
- Configura Game Center prima della review: leaderboard e achievement devono esistere in App Store Connect se la capability resta attiva.
- Completa `docs/APP_STORE_EXTERNAL_FIELDS.md` con Privacy Policy URL, Support URL, contatto App Review, copyright, stato Critical Alerts e stato Game Center.
- Pubblica una Privacy Policy su URL pubblico. Puoi partire da `docs/PRIVACY_POLICY_DRAFT.md`, ma prima rimuovi il placeholder di contatto finale.
- Pubblica una pagina Support su URL pubblico. Puoi partire da `docs/SUPPORT_PAGE_DRAFT.md`, ma prima inserisci contatto reale.
- Puoi generare HTML statico pronto da caricare con `scripts/export-public-pages.sh --contact-email <email> --privacy-url <url> --support-url <url>`.
- Inserisci Privacy Policy URL in App Store Connect e copia Privacy/Support URL in `project.yml` (`SoleaPrivacyPolicyURL`, `SoleaSupportURL`) per mostrarli anche dentro l'app.
- Quando è disponibile l'URL pubblico della scheda App Store, valorizza `SoleaAppStoreURL` in `project.yml`: verrà aggiunto automaticamente alle condivisioni social.
- Gli screenshot minimi sono gia' in `AppStore/Screenshots`; sostituiscili o aggiungine altri se vuoi una scheda piu' completa, poi valida con `scripts/validate-app-store-screenshots.sh --required`.
- Compila Export Compliance, App Privacy, Regulated Medical Device e Age Rating usando la bozza in `docs/APP_STORE_CONNECT_ANSWERS.md`.
- App Privacy: per la configurazione attuale con `SoleaCoachProxyURL` vuoto, le foto del diario, il fototipo, le sessioni, il Time in Daylight HealthKit e la posizione restano sul dispositivo o nei servizi Apple richiesti dall'utente. La vitamina D resta una stima in-app. Se abiliti il proxy cloud, aggiorna le risposte privacy perché il contesto del coach viene inviato al server.
- In-App Purchase: crea e localizza `com.davidecapurro.Solea.plus.annual`
  (auto-renewable, €19,99/anno) e `com.davidecapurro.Solea.plus.seasonal`
  (non-renewing, €9,99, accesso app-side 120 giorni). Il mensile
  `com.davidecapurro.Solea.plus.monthly` resta opzionale/non promosso finché non
  decidi di attivarlo. Sottoponi gli IAP alla review con la build.
- Encryption: `ITSAppUsesNonExemptEncryption = false` è già impostato.
- Push Notifications: `aps-environment` usa `$(APS_ENVIRONMENT)` nel file sorgente; Debug imposta `development`, Release imposta `production`. Il profilo di distribuzione deve comunque firmare il bundle finale con ambiente APNs `production`.
- Critical Alerts: **non usati**. Lo stop alert usa `UNNotificationSound.default` e l'autorizzazione richiesta è `[.alert, .sound]`. L'App ID e il profilo NON devono includere `com.apple.developer.usernotifications.critical-alerts`.
- Age Rating: completa il questionario in App Store Connect.
- Accessibility Nutrition Label: opzionale, ma consigliato per iOS 26+.

## Build e upload

1. Rigenera il progetto: `xcodegen generate`.
2. Verifica di avere almeno 2 GiB liberi sul disco: il preflight crea una build Release e un archive unsigned temporaneo.
3. Esegui `scripts/validate-app-store-metadata.sh` se modifichi nome, sottotitolo, keyword, promotional text, description o review notes. I limiti usati seguono la reference App Store Connect di Apple: nome 2-30 caratteri, sottotitolo 30 caratteri, promotional text 170 caratteri, description 4000 caratteri, keyword 100 byte.
4. Esegui `scripts/validate-game-center-config.sh` se modifichi badge, classifiche o `docs/GAME_CENTER_SETUP.md`.
5. Esegui `scripts/export-app-store-metadata.sh` e usa i file in `AppStore/Metadata/it/` per compilare App Store Connect.
6. Esegui `scripts/validate-app-store-external-fields.sh --strict` dopo aver completato i campi esterni in `docs/APP_STORE_EXTERNAL_FIELDS.md`.
7. Installa l'icona finale con `scripts/install-app-icon.sh <path-to-1024-png>`.
8. Esegui `scripts/prepare-app-store-package.sh` per sincronizzare URL, rigenerare progetto, esportare metadata/pagine pubbliche e vedere la readiness.
9. Esegui `scripts/app-store-readiness-report.sh` per rivedere tutti i blocchi residui in un solo report.
10. Esegui `scripts/app-store-final-check.sh`. Il gate finale richiama metadata, Game Center, campi esterni strict, preflight strict, screenshot e AppIcon. Finché l'icona finale non è inserita puoi usare `scripts/app-store-preflight.sh --skip-icon-check`, ma non per la verifica finale.
11. Apri `Solea.xcodeproj`.
12. In Signing & Capabilities seleziona il Team Apple Developer per tutti i target. Nessun entitlement Critical Alerts richiesto.
13. Build Release su device generico o archivio da Xcode.
14. Dopo l'archive firmato, esegui `scripts/app-store-final-check.sh --archive <path>.xcarchive` per verificare firma, APNs `production` e capability effettive insieme agli altri gate.
15. In Organizer valida l'archivio, poi carica su App Store Connect.
16. Per archive/upload da CLI, usa `scripts/archive-app-store.sh --allow-provisioning-updates --export-path AppStore/Exports/Solea`.
