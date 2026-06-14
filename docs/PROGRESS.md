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
- [x] Live Activity (Dynamic Island + lock screen) per la sessione attiva,
      aggiornata ogni 30 s e a ogni refresh UV
- [x] Widget home/lock screen (UV, burn risk, tempo sicuro) via snapshot in App Group;
      dati mancanti o vecchi dichiarati esplicitamente, mai inventati
- [x] HealthKit: Time in Daylight + vitamina D (pulsante "Salva su Salute" nel riepilogo,
      errori e permessi negati mostrati con retry)

## M4 — Chicche
- [x] Foto-diario: import foto, analisi tono on-device (Vision/CoreImage), slider prima/dopo
- [x] Tan planner vacanze (`TanPlanner.swift` in SoleaCore, con test) + UI e persistenza
- [x] Modalità lettino/solarium (UV-equivalente dalla potenza lampade)
- [x] Promemoria idratazione & after-sun

## M5 — Social & Watch
- [x] Game Center: classifiche (minuti smart settimanali, streak) + achievement;
      streak/badge in SoleaCore con test
- [x] Share card per condivisione social (ImageRenderer + share sheet)
- [x] App watchOS: UV a colpo d'occhio, tempo sicuro, timer sessione con haptic
- [x] Sync profilo iPhone↔Watch via WatchConnectivity: il fototipo viaggia
      dall'iPhone al Watch via `updateApplicationContext` (`PhoneConnectivityService`
      / `WatchProfileSync`); il picker al polso resta come override/fallback,
      errori di sync mostrati nel Profilo (mai silenziati)

## M6 — Coach Solare AI
- [x] Proxy Claude (`server/coach-proxy`, Cloudflare Worker TS) con streaming SSE,
      prompt caching e rate limit per utente (verificato qui: typecheck + test logica)
- [x] OnDeviceCoach (FoundationModels, gated iOS 26)
- [x] CloudCoach (consumo SSE dal proxy, errori propagati)
- [x] CoachRouter ibrido con fallback bidirezionale (complessità/connettività)
- [x] Chat UI del Coach Solare con contesto utente (solo fototipo/UV/sessioni, mai foto)
- [ ] Deploy proxy + `proxyURL` in CoachConfiguration — a carico dell'utente
      (istruzioni nel README)

## Attività a carico dell'utente (fuori dal codice)
- [ ] Asset grafici con Claude Design (vedi `docs/ASSETS.md`)
- [ ] Account Apple Developer: capability WeatherKit + signing in Xcode
- [ ] Deploy del proxy su Cloudflare (M6) con `ANTHROPIC_API_KEY`
