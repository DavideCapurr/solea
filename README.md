# ☀️ Solea

App iOS per abbronzarsi con più consapevolezza. **Tan-first, ma smart.**

La specifica completa è in [`docs/SPEC.md`](docs/SPEC.md), lo stato di avanzamento in
[`docs/PROGRESS.md`](docs/PROGRESS.md), e le assunzioni scientifiche sono in
[`docs/SCIENTIFIC_MODEL.md`](docs/SCIENTIFIC_MODEL.md).
La checklist per App Store Connect è in [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md).
La procedura completa di upload e invio in review è in
[`docs/APP_STORE_UPLOAD_RUNBOOK.md`](docs/APP_STORE_UPLOAD_RUNBOOK.md).

## Struttura

| Cartella | Contenuto |
|---|---|
| `SoleaCore/` | Package SwiftPM con la logica di dominio pura (fototipo, limite prudente, burn risk, golden hours) + unit test |
| `App/` | Target iOS (SwiftUI, iOS 17+) |
| `docs/` | Specifica, avanzamento, asset richiesti |
| `server/coach-proxy/` | (M6) Proxy Cloudflare Worker per il Coach AI |

Il file `Solea.xcodeproj` **non è versionato**: viene generato da `project.yml` con XcodeGen.

## Setup (su Mac)

```sh
brew install xcodegen
xcodegen generate
open Solea.xcodeproj
```

Prima dell'archivio finale puoi eseguire il preflight locale, che controlla anche build Release device e archive unsigned:

```sh
scripts/app-store-preflight.sh
```

Le opzioni di export/upload App Store Connect sono in `AppStore/ExportOptions-AppStoreConnect.plist`.
Gli screenshot App Store si validano con `scripts/validate-app-store-screenshots.sh --required`.
Dopo un archive firmato puoi controllare firma e capability finali con `scripts/validate-signed-archive.sh <path>.xcarchive`.

In Xcode:
1. **Signing & Capabilities** → seleziona il tuo team (account Apple Developer).
2. La capability **WeatherKit** è già nel file di entitlements: abilita WeatherKit per
   l'App ID su [developer.apple.com](https://developer.apple.com/account) (Identifiers →
   App ID → WeatherKit). Senza, le richieste UV falliscono con errore di autorizzazione
   (l'app lo mostra a schermo, con retry).
3. Esegui su simulatore o dispositivo (⌘R). Nota: su simulatore imposta una posizione in
   Features → Location.

## Test

I test unitari vivono in `SoleaCore`:

```sh
cd SoleaCore && swift test        # da terminale (macOS)
```

oppure apri il package in Xcode ed esegui ⌘U.

## Coach AI (M6)

Il Coach è ibrido:

- **On-device** (Apple Foundation Models, iOS 26+): funziona da solo, gratis e offline, senza alcuna configurazione.
- **Cloud** (proxy provider-agnostic): più capace, per chat lunghe e domande complesse.
  Il Worker incluso usa Gemini 2.5 Flash-Lite come adapter cloud scelto;
  Mistral `ministral-3b-latest` e Anthropic Claude Sonnet restano fallback configurabili.

Per abilitare il livello cloud serve deployare il proxy in `server/coach-proxy`:

```sh
cd server/coach-proxy
npm install
cp .dev.vars.example .dev.vars                 # per `npm run dev`; inserisci la tua chiave Gemini
npx wrangler kv namespace create RATE_LIMIT     # incolla l'id in wrangler.toml
npx wrangler secret put GEMINI_API_KEY           # la chiave resta lato server
npm run deploy
```

Verifica il deploy con `GET https://<tuo-worker>/health`: deve rispondere con
`"ready": true`, provider `gemini` e modello `gemini-2.5-flash-lite`.

Poi compila l'app passando l'URL del Worker al build setting
`SOLEA_COACH_PROXY_URL`, che viene inserito in `SoleaCoachProxyURL`:

```sh
xcodebuild \
  -project Solea.xcodeproj \
  -scheme Solea \
  -destination 'generic/platform=iOS Simulator' \
  SOLEA_COACH_PROXY_URL='https://<tuo-worker>.workers.dev' \
  build
```

Finché `SOLEA_COACH_PROXY_URL` resta vuoto, l'app usa solo il coach on-device.
Le API key dei provider non sono **mai** nell'app: vivono solo come secret di Cloudflare.

Verifica locale del proxy (senza deploy):

```sh
cd server/coach-proxy
npm run check
npm run dev
curl http://localhost:8787/health
```

## Smoke test M1

1. Primo avvio → onboarding con disclaimer e quiz fototipo (6 domande).
2. Al termine il fototipo calcolato viene salvato; riavviando l'app si va dritti alla tab "Oggi".
3. "Oggi" mostra: UV attuale, semaforo burn risk, limite prudente (senza protezione e con SPF 30),
   golden hours del giorno e grafico UV delle prossime ore.
4. Negando i permessi di posizione compare un errore chiaro con pulsante Riprova.
5. Tab Profilo → "Rifai il quiz" riporta all'onboarding.

## Smoke test sync Watch (M5)

Con iPhone + Apple Watch abbinati e l'app installata su entrambi:

1. Completa l'onboarding sull'iPhone: il fototipo viene inviato al Watch via
   WatchConnectivity (`updateApplicationContext`).
2. Apri l'app sul Watch: il picker "Fototipo" riflette il valore dell'iPhone
   (puoi comunque cambiarlo come override locale).
3. Rifai il quiz sull'iPhone con un fototipo diverso → al successivo apri/refresh
   del Watch il valore si aggiorna.
4. Se la sincronizzazione fallisce, la tab Profilo dell'iPhone mostra un avviso
   (l'errore non viene mai nascosto); il Watch resta usabile con la scelta manuale.
