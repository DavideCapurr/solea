# Asset grafici — da generare con Claude Design

Il codice usa SF Symbols e colori di sistema; gli asset "di carattere" vengono generati
dall'utente con Claude Design e inseriti in `App/Resources/Assets.xcassets` con i nomi
qui sotto. Finché mancano, l'app usa i fallback indicati.

| Nome asset | Uso | Formato consigliato | Fallback attuale |
|---|---|---|---|
| `AppIcon` | Icona app | 1024×1024 PNG senza trasparenza | icona vuota |
| `OnboardingHero` | Illustrazione schermata di benvenuto | PNG/HEIC ~1200px, tema sole | SF Symbol `sun.max.fill` |
| `ShareCardBackground` | (M5) sfondo della share card | 1080×1920 PNG | gradiente di sistema |

Linee guida di stile: caldo, solare, palette ambra/terracotta su crema; niente viola/gradienti "AI".
