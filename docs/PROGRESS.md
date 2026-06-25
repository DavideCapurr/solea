# Stato di avanzamento — Solea

> Questo file è la fonte di verità per il lavoro multi-sessione: ogni sessione lo legge
> insieme a `docs/SPEC.md`, riparte dal primo task non spuntato e lo aggiorna a ogni commit.

## M1 — Fondamenta
- [x] `project.yml` (XcodeGen) con target iOS 17+, entitlements WeatherKit
- [x] Package `SoleaCore`: Fitzpatrick + quiz, MED, SafeExposure, BurnRisk, GoldenHours
- [x] Unit test per ogni modulo di `SoleaCore`
- [x] App: onboarding con quiz fototipo + disclaimer
- [x] App: schermata Oggi (UV attuale + previsioni via WeatherKit, golden hours, burn risk)
- [x] App: piano consigliato automatico ("quanto tempo stare al sole" o "ombra
      oggi") in base a fototipo, UV attuale, dose già accumulata oggi e
      condizione pelle; l'utente non deve scegliere l'obiettivo tecnico
- [x] Localizzazione it (sorgente) + en, README con istruzioni di setup

## M2 — Sessioni
- [x] Modello SwiftData `TanSession` (+ `ExposedZones` e `VitaminD` in SoleaCore, con test)
- [ ] Sync CloudKit — rimandata: richiede il container iCloud configurato
      dall'utente su developer.apple.com (entitlement + capability); da riprendere
      quando l'account è pronto
- [x] Timer sessione: obiettivo con durata target, pausa/riprendi, SPF/zone
      esposte, countdown sicurezza, tracking fronte/retro, timeline promemoria,
      dose integrata al secondo solo mentre esposto, UV aggiornato ogni 10 minuti
      (errori di refresh mostrati come avviso, mai nascosti)
- [x] Promemoria "girati" / "obiettivo raggiunto" / "riapplica crema"
      (notifiche locali) + alert stop
- [x] Riepilogo fine sessione (tempo effettivo al sole, pause, UV medio, dose UV,
      % MED, vitamina D stimata, uniformità fronte/retro, riflessione pelle/note e prossima azione)
- [x] Diario con storico, dettaglio sessioni, statistiche settimanali e dose UV cumulativa nel burn risk

## M3 — Integrazione sistema
- [x] Live Activity (Dynamic Island + lock screen) per la sessione attiva,
      aggiornata ogni 30 s e a ogni refresh UV
- [x] Widget home/lock screen (UV, burn risk, limite prudente) via snapshot in App Group;
      dati mancanti o vecchi dichiarati esplicitamente, mai inventati
- [x] HealthKit: Time in Daylight (pulsante "Salva su Salute" nel riepilogo,
      errori e permessi negati mostrati con retry)

## M4 — Chicche
- [x] Foto-diario: import foto, analisi tono on-device (Vision/CoreImage), slider prima/dopo
- [x] Tan planner vacanze (`TanPlanner.swift` in SoleaCore, con test) + UI e persistenza
- [x] Modalità lettino/solarium (UV-equivalente dalla potenza lampade)
- [x] Promemoria idratazione & after-sun

## M5 — Social & Watch
- [x] Game Center: classifiche (minuti smart settimanali, streak) + achievement;
      streak/badge in SoleaCore con test
- [x] Share card verticali 1080×1920 (ImageRenderer + share sheet) da onboarding,
      check quotidiano, riepilogo sessione, streak e foto prima/dopo; link App Store
      aggiunto automaticamente quando configurato
- [x] App watchOS: UV a colpo d'occhio, limite prudente, timer sessione con haptic
- [x] Sync profilo iPhone↔Watch via WatchConnectivity: il fototipo viaggia
      dall'iPhone al Watch via `updateApplicationContext` (`PhoneConnectivityService`
      / `WatchProfileSync`); il picker al polso resta come override/fallback,
      errori di sync mostrati nel Profilo (mai silenziati)

## M6 — Coach Solare AI
- [x] Decisione LLM tracciata: Apple on-device come default locale, cloud provider-agnostic,
      Gemini 2.5 Flash-Lite come default cloud scelto, Mistral/Claude fallback
- [x] Proxy cloud (`server/coach-proxy`, Cloudflare Worker TS) con adapter Mistral,
      Gemini e Anthropic, streaming SSE e rate limit per utente
- [x] Test locali del proxy cloud: contratto SSE Gemini, secret mancante senza consumo
      quota, rate limit per utente e richieste malformate
- [x] Limiti input lato proxy per contenere costi/abusi: max messaggi,
      max caratteri per messaggio/contesto, ruoli validati prima del provider
- [x] Health check proxy (`GET /health`) e setup locale sicuro con `.dev.vars`
      ignorato da git per verificare Gemini senza consumare quota
- [x] Limiti input lato app: messaggi troppo lunghi bloccati prima dell'invio
      e cronologia inviata al coach ridotta alla coda utile più recente
- [x] Contesto Coach arricchito ma minimale: fototipo/UV, dose MED oggi,
      sessioni recenti senza note/foto e prossimo piano vacanze; dati mancanti
      dichiarati esplicitamente e destinazione sanitizzata
- [x] OnDeviceCoach (FoundationModels, gated iOS 26)
- [x] CloudCoach (consumo SSE dal proxy, errori propagati)
- [x] CoachRouter ibrido con fallback bidirezionale (complessità/connettività)
- [x] Chat UI del Coach Solare con contesto utente (solo fototipo/UV/sessioni, mai foto)
- [x] Stato disponibilità Coach in UI: on-device, proxy cloud e connettività visibili
      prima della chat
- [x] Build setting `SOLEA_COACH_PROXY_URL` per abilitare Gemini cloud senza
      hardcodare URL o secret nel repository
- [ ] Deploy proxy + build con `SOLEA_COACH_PROXY_URL` — a carico dell'utente
      (istruzioni nel README)

## Attività a carico dell'utente (fuori dal codice)
- [ ] Asset grafici con Claude Design (vedi `docs/ASSETS.md`)
- [ ] Account Apple Developer: capability WeatherKit + signing in Xcode
- [ ] Deploy del proxy su Cloudflare (M6) con `GEMINI_API_KEY`
