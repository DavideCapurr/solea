# Stato di avanzamento — Solea

> Questo file è la fonte di verità per il lavoro multi-sessione: ogni sessione lo legge
> insieme a `docs/SPEC.md`, riparte dal primo task non spuntato e lo aggiorna a ogni commit.

## M1 — Fondamenta
- [x] `project.yml` (XcodeGen) con target iOS 17+, entitlements WeatherKit
- [x] Package `SoleaCore`: Fitzpatrick + quiz, MED, SafeExposure, BurnRisk, GoldenHours
- [x] Unit test per ogni modulo di `SoleaCore`
- [x] App: onboarding con quiz fototipo + disclaimer
- [x] App: schermata Oggi (UV attuale + previsioni via WeatherKit, golden hours, burn risk)
- [x] Localizzazione it (sorgente) + en, README con istruzioni di setup

## M2 — Sessioni
- [x] Modello SwiftData `TanSession` (+ `ExposedZones` e `VitaminD` in SoleaCore, con test)
- [ ] Sync CloudKit — rimandata: richiede il container iCloud configurato
      dall'utente su developer.apple.com (entitlement + capability); da riprendere
      quando l'account è pronto
- [x] Timer sessione: SPF/zone esposte, countdown sicurezza, dose integrata al secondo,
      UV aggiornato ogni 10 minuti (errori di refresh mostrati come avviso, mai nascosti)
- [x] Promemoria "girati" / "riapplica crema" (notifiche locali) + alert stop
- [x] Riepilogo fine sessione (durata, UV medio, dose UV, % MED, vitamina D stimata)
- [x] Diario con storico, statistiche settimanali e dose UV cumulativa nel burn risk

## M3 — Integrazione sistema
- [ ] Live Activity (Dynamic Island + lock screen) per la sessione attiva
- [ ] Widget home/lock screen (UV, burn risk, limite prudente)
- [ ] HealthKit: Time in Daylight + vitamina D (`VitaminD.swift` in SoleaCore)

## M4 — Chicche
- [ ] Foto-diario: camera con overlay, analisi tono on-device, slider prima/dopo
- [ ] Tan planner vacanze (`TanPlanner.swift` in SoleaCore)
- [ ] Modalità lettino/solarium
- [ ] Promemoria idratazione & after-sun

## M5 — Social & Watch
- [ ] Game Center: classifiche + achievement; streak/badge in SoleaCore
- [ ] Share card per condivisione social
- [ ] App watchOS: UV, avvio sessione, timer con haptic

## M6 — Coach Solare AI
- [ ] Proxy Claude (`server/coach-proxy`, Cloudflare Worker TS) con streaming SSE,
      prompt caching e rate limit
- [ ] OnDeviceCoach (FoundationModels, gated iOS 26)
- [ ] CoachRouter ibrido con fallback bidirezionale
- [ ] Chat UI del Coach Solare

## Attività a carico dell'utente (fuori dal codice)
- [ ] Asset grafici con Claude Design (vedi `docs/ASSETS.md`)
- [ ] Account Apple Developer: capability WeatherKit + signing in Xcode
- [ ] Deploy del proxy su Cloudflare (M6) con `ANTHROPIC_API_KEY`
