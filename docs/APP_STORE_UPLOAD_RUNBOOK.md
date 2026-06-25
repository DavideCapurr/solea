# Solea App Store Connect upload runbook

Procedura finale per caricare Solea 1.0 su App Store Connect. Esegui i passaggi
in ordine: i gate locali sono intenzionalmente severi e devono passare prima
dell'upload.

## 1. Completa i prerequisiti esterni

- Verifica che l'Account Holder abbia accettato gli accordi Apple correnti.
- Nel Developer Portal configura gli App ID espliciti:
  - `com.davidecapurro.Solea`: WeatherKit, HealthKit, Game Center, App Groups,
    Push Notifications e Critical Alerts.
  - `com.davidecapurro.Solea.Widgets`: App Groups.
  - `com.davidecapurro.Solea.watchkitapp`: WeatherKit.
- Crea e associa `group.com.davidecapurro.solea` all'app iOS e al widget.
- Ottieni l'approvazione Apple per
  `com.apple.developer.usernotifications.critical-alerts`. Solea usa
  `UNNotificationSound.defaultCritical`, quindi non procedere con un profilo
  che non contiene questo entitlement.
  - Richiesta inviata il 2026-06-22, request ID `SKFHX9458G`; in attesa di
    approvazione Apple.
- Crea in App Store Connect tutti i componenti elencati in
  `docs/GAME_CENTER_SETUP.md`.
- Pubblica Privacy Policy e pagina Support su URL HTTPS pubblici.
- Completa ogni placeholder in `docs/APP_STORE_EXTERNAL_FIELDS.md`.

## 2. Prepara il repository

Esegui:

```sh
scripts/prepare-app-store-package.sh --include-preflight
```

Il comando sincronizza gli URL dentro l'app, rigenera il progetto, esporta i
metadata e le pagine pubbliche, quindi produce il readiness report. Deve
riportare zero blocker.

Verifica anche i test core:

```sh
cd SoleaCore
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
cd ..
```

## 3. Crea il record App Store Connect

In App Store Connect apri Apps, premi `+`, scegli `New App` e inserisci:

- Platform: iOS.
- Name: Solea.
- Primary language: Italian.
- Bundle ID: `com.davidecapurro.Solea`.
- SKU: `solea-ios`.
- User Access: quello previsto per il tuo team.

Apple richiede che il record esista prima dell'upload. La Watch app companion
resta nello stesso record iOS.

## 4. Compila la scheda prodotto

Usa i file in `AppStore/Metadata/it/` per:

- nome, sottotitolo, promotional text, description e keywords;
- Review Notes;
- risposte Export Compliance, App Privacy e Age Rating.

Completa inoltre:

- Support URL e Privacy Policy URL dai valori validati nel file dei campi
  esterni;
- categoria primaria e secondaria;
- copyright;
- disponibilità, prezzo e metodo di distribuzione;
- contatto App Review;
- release option desiderata, preferibilmente manuale per la prima versione;
- dichiarazione Regulated Medical Device: No;
- export compliance coerente con `ITSAppUsesNonExemptEncryption = false`.

Carica gli screenshot validati in questo ordine:

- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/01-solea-check.png`;
- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/02-live-session.png`;
- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/03-safety-reminders.png`;
- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/04-session-plan.png`;
- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/05-progress-diary.png`;
- iPhone 6,9": `AppStore/Screenshots/iPhone-6.9/06-vacation-planner.png`;
- iPhone 6,5" se richiesto dal riquadro ASC: stessi nomi in
  `AppStore/Screenshots/iPhone-6.5/`;
- Apple Watch: `AppStore/Screenshots/Apple-Watch/01-uv.png`.

La descrizione deve includere la funzionalità Apple Watch. Apple richiede anche
lo screenshot Watch per un'app iOS con companion watchOS.

## 5. Pubblica App Privacy

In `App Privacy`:

- inserisci il Privacy Policy URL;
- rispondi usando `docs/APP_STORE_CONNECT_ANSWERS.md`;
- verifica che il coach cloud sia ancora disabilitato
  (`SoleaCoachProxyURL` vuoto);
- completa ogni data type e premi `Publish`.

Le risposte devono coprire anche i servizi Apple usati dalla build, inclusa
l'attività Game Center descritta nella bozza.

## 6. Configura Game Center

In App Store Connect > Game Center crea esattamente:

- leaderboard `solea.weekly.smart.minutes`;
- leaderboard `solea.longest.streak`;
- achievement `firstSession`;
- achievement `weekStreak`;
- achievement `plannerCompleted`;
- achievement `vitaminD10k`.

Per la prima pubblicazione aggiungi questi componenti alla stessa submission
della versione 1.0. Apple richiede la review dei componenti nuovi o modificati.

## 7. Firma e crea l'archive

Apri `Solea.xcodeproj` in Xcode e controlla:

- scheme `Solea`;
- destination `Any iOS Device (arm64)` o device generico equivalente;
- configuration Release;
- Team corretto per app, widget e Watch app;
- Automatically manage signing attivo, oppure profili distribution equivalenti;
- version `1.0.0`, build `1`;
- profilo iOS con APNs `production` e Critical Alerts approvato.

Poi scegli `Product > Archive`.

In alternativa puoi usare:

```sh
scripts/archive-app-store.sh --allow-provisioning-updates \
  --export-path AppStore/Exports/Solea
```

## 8. Valida l'archive firmato

Individua il file `.xcarchive` creato da Xcode e lancia:

```sh
scripts/app-store-final-check.sh --archive "/percorso/Solea.xcarchive"
```

Il controllo deve confermare:

- firma valida e bundle embedded presenti;
- bundle ID, versione e build corretti;
- privacy manifest inclusi;
- APNs `production`;
- WeatherKit, HealthKit, Game Center, App Group e Critical Alerts effettivamente
  presenti negli entitlements firmati.

Non caricare l'archive se questo comando fallisce.

## 9. Valida e carica da Xcode

In Xcode Organizer:

1. Seleziona l'archive Solea.
2. Premi `Validate App` e risolvi ogni errore.
3. Premi `Distribute App`.
4. Seleziona `App Store Connect` e poi `Upload`.
5. Mantieni upload dei simboli attivo.
6. Conferma firma e profili mostrati da Xcode.
7. Completa l'upload e conserva il delivery log.

Apple supporta anche upload CLI/API, ma Organizer è il percorso consigliato per
la prima submission perché mostra chiaramente errori di firma e provisioning.

## 10. Dopo l'upload

- Attendi che la build completi il processing in App Store Connect.
- Risolvi eventuali warning o richieste Export Compliance.
- Nella versione iOS 1.0, sezione Build, seleziona la build `1`.
- Verifica che la Watch app e il widget risultino inclusi nella build elaborata.
- Esegui almeno un controllo TestFlight interno prima della submission finale.
- Ricontrolla Review Notes, contatto App Review e assenza di demo account
  richiesto (`Sign-in required: No`).

## 11. Invia in review

1. Nella versione 1.0 premi `Add for Review`.
2. Aggiungi alla stessa draft submission i componenti Game Center della prima
   pubblicazione.
3. Apri `Draft Submissions` e verifica che versione e componenti siano tutti
   presenti e `Ready for Review`.
4. Premi `Submit for Review`.
5. Controlla che lo stato passi a `Waiting for Review` e poi `In Review`.

## Gate di completamento

Il caricamento è pronto soltanto quando:

- `scripts/app-store-readiness-report.sh --include-preflight` mostra zero
  blocker;
- il final check dell'archive firmato passa;
- Organizer valida e carica senza errori;
- la build elaborata è selezionata sulla versione 1.0;
- metadata, privacy e Game Center sono inclusi nella draft submission;
- App Store Connect accetta `Submit for Review`.

## Fonti Apple

- [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Add watchOS app information](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-watchos-app-information)
- [Submit Game Center components](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-game-center-components/)
- [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
