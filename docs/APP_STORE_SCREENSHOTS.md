# App Store screenshot checklist

Specifica aggiornata al 17 giugno 2026 per la scheda App Store di Solea.

Fonti Apple consultate il 17 giugno 2026:

- `Screenshot specifications` in App Store Connect Help.
- `Upload app previews and screenshots` in App Store Connect Help.

## iPhone

Solea e' iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), quindi non servono screenshot iPad.

Carica da 1 a 10 screenshot in `.png`, `.jpg` o `.jpeg` per set richiesto.

Percorso validato dal preflight:

- `AppStore/Screenshots/iPhone-6.9`

Set principale consigliato:

- iPhone 6.9" Display: `1320 x 2868` portrait, oppure `2868 x 1320` landscape.
- Apple accetta anche per 6.9": `1290 x 2796` o `1260 x 2736` portrait.

Set opzionale se vuoi controllare rendering su display medio:

- iPhone 6.3" Display: `1179 x 2556` o `1206 x 2622` portrait.
- Percorso opzionale: `AppStore/Screenshots/iPhone-6.3`

Shot list consigliata:

- Today: indice UV, limite prudente, suggerimento sessione.
- Sessione attiva: timer, stop alert/limite prudente, fronte-retro.
- Diario: storico sessioni e risposta della pelle.
- Planner: piano graduale di esposizione.
- Profilo: fototipo, streak, badge/Game Center.

## Apple Watch

La build include `SoleaWatch.app`, quindi App Store Connect richiede screenshot Apple Watch.

Usa un solo formato Watch in modo coerente per tutte le localizzazioni:

- Percorso validato dal preflight: `AppStore/Screenshots/Apple-Watch`

- Ultra 3: `422 x 514`.
- Ultra 2 / Ultra: `410 x 502`.
- Series 11 / Series 10: `416 x 496`.
- Series 9 / Series 8 / Series 7: `396 x 484`.
- Series 6 / Series 5 / Series 4 / SE 3 / SE: `368 x 448`.
- Series 3: `312 x 390`.

Shot list consigliata:

- UV attuale al polso.
- Timer sessione.
- Picker fototipo/sync profilo.

## Qualita'

- Usa dati dimostrativi realistici, senza foto personali identificabili.
- Evita promesse mediche: Solea mostra stime informative e limiti prudenziali.
- Se mostri Critical Alerts, rappresentale come stop alert di sicurezza, non come promemoria marketing.

## Dati demo

Per preparare screenshot coerenti senza dipendere da WeatherKit, posizione o onboarding,
avvia una build Debug con il launch argument:

```sh
-soleaScreenshotDemo
```

La modalita' demo popola profilo, diario e planner solo in `DEBUG`, e la schermata
Today usa un indice UV dimostrativo stabile. Prima di una sessione screenshot pulita,
disinstalla l'app dal simulatore e rilanciala con l'argomento demo.

## Validazione locale

Quando gli screenshot finali sono pronti:

```sh
scripts/validate-app-store-screenshots.sh --required
```
