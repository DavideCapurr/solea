# Asset grafici — da generare con Claude Design

Il codice usa SF Symbols e colori di sistema; gli asset "di carattere" vengono generati
dall'utente con Claude Design e inseriti in `App/Resources/Assets.xcassets` con i nomi
qui sotto. Finché mancano, l'app usa i fallback indicati.

| Nome asset | Uso | Formato consigliato | Fallback attuale |
|---|---|---|---|
| `AppIcon` | Icona app | 1024×1024 PNG senza trasparenza | installata |
| `OnboardingHero` | Illustrazione schermata di benvenuto | PNG 1536×1024, tema sole | installata |
| Share card | Story condivisibile | 1080×1920 PNG | generata nativamente da SwiftUI |

Linee guida di stile: caldo, solare, palette ambra/terracotta su crema; niente viola/gradienti "AI".

Quando l'icona finale e' pronta, installala con:

```sh
scripts/install-app-icon.sh /percorso/alla/tua-icona-1024.png
scripts/app-store-preflight.sh
```
