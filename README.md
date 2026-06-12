# ☀️ Solea

App iOS per abbronzarsi al meglio, senza scottarsi. **Tan-first, ma smart.**

La specifica completa è in [`docs/SPEC.md`](docs/SPEC.md), lo stato di avanzamento in
[`docs/PROGRESS.md`](docs/PROGRESS.md), e le assunzioni scientifiche sono in
[`docs/SCIENTIFIC_MODEL.md`](docs/SCIENTIFIC_MODEL.md).

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

## Smoke test M1

1. Primo avvio → onboarding con disclaimer e quiz fototipo (6 domande).
2. Al termine il fototipo calcolato viene salvato; riavviando l'app si va dritti alla tab "Oggi".
3. "Oggi" mostra: UV attuale, semaforo burn risk, limite prudente (senza protezione e con SPF 30),
   golden hours del giorno e grafico UV delle prossime ore.
4. Negando i permessi di posizione compare un errore chiaro con pulsante Riprova.
5. Tab Profilo → "Rifai il quiz" riporta all'onboarding.
