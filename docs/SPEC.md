# ☀️ Solea — Specifica di prodotto v1

> App iOS per abbronzarsi con più consapevolezza. **Tan-first, ma smart.**

- **Filosofia**: l'obiettivo dell'utente è un'abbronzatura bella e uniforme; l'app lo aiuta a raggiungerla in modo intelligente e prudente. Tono motivazionale, non medicale.
- **Prezzo**: freemium. Gratis: UV live, burn risk, limite prudente,
  quiz fototipo, timer base, diario base e alert di sicurezza. Solea Plus:
  planner vacanze completo, coach AI cloud, foto-diario prima/dopo,
  statistiche storiche, reminder personalizzati, Watch/Live Activity avanzati
  e share card premium.
- **Piattaforma**: iOS 17+, SwiftUI, companion Apple Watch.
- **Backend**: WeatherKit, Game Center, StoreKit e, solo per il Coach Plus se
  configurato, proxy cloud senza API key nel binario.

---

## 1. Funzionalità core

### 1.1 UV in tempo reale
- Indice UV attuale dalla posizione GPS (WeatherKit).
- Previsioni UV orarie (oggi) e giornaliere (7 giorni) con grafico della curva.
- **Golden hours**: fasce orarie evidenziate in cui il rapporto abbronzatura/rischio è ottimale per il fototipo dell'utente.
- Indicatore **burn risk** live a semaforo (verde/giallo/rosso) che combina UV attuale, tempo già esposto oggi e SPF applicato.

### 1.2 Profilo pelle
- Onboarding con quiz fototipo (scala Fitzpatrick I–VI): tono pelle, colore occhi/capelli, lentiggini, reazione tipica al sole.
- Da fototipo + UV + SPF l'app calcola un **limite prudente di esposizione** (sotto la MED — Minimal Erythema Dose — per fototipo).
- La schermata Oggi chiede solo la **condizione attuale della pelle** (bene, calda,
  tira, arrossata): è un dato fisico, non una scelta di obiettivo.
- Il profilo è modificabile e si raffina nel tempo con i dati delle sessioni.

### 1.3 Sessione di abbronzatura (timer)
- Piano consigliato automatico: Solea decide cosa fare in base a fototipo, UV
  attuale, dose già presa oggi e condizione pelle. L'utente vede un'azione
  chiara (es. "41 min al sole" oppure "Ombra oggi"), non un picker di obiettivi.
- L'obiettivo tecnico della sessione (vitamina D, tan graduale, prudenza) è
  scelto dall'advisor e salvato nel diario.
- Avvio sessione dal piano: durata, SPF e zone sono precompilati; l'utente può
  correggere dettagli pratici come SPF realmente applicato e zone esposte.
- Countdown del limite prudente rimanente, ricalcolato se l'UV cambia.
- Progresso verso il target della sessione, separato dal limite di sicurezza
  (Plus).
- Pausa/riprendi per ombra, bagno o interruzioni: dose e target avanzano solo
  durante il tempo effettivamente esposto.
- Tracking fronte/retro durante la sessione per mantenere uniforme l'abbronzatura (Plus).
- Promemoria **"girati!"** a intervalli configurabili per un tan uniforme (Plus).
- Promemoria quando la durata obiettivo è raggiunta (Plus).
- Promemoria **riapplica la crema** (ogni 2h o dopo il bagno, configurabile) (Plus).
- Timeline dei prossimi promemoria visibile durante la sessione (Plus).
- Alert di stop all'avvicinarsi della soglia di rischio scottatura.
- A fine sessione: riepilogo (tempo effettivo al sole, pause, UV medio, dose UV
  stimata, vitamina D stimata), bilanciamento fronte/retro e riflessione pelle/note.

### 1.4 Diario e statistiche
- Storico sessioni con tempo effettivo al sole, pause, obiettivo, UV medio, SPF,
  bilanciamento fronte/retro, sensazione pelle, note e dose UV cumulativa.
- Statistiche settimanali base gratuite; trend storici e andamento mensile in
  Solea Plus.
- Dose UV cumulata della giornata sempre visibile (somma di più sessioni).

---

## 2. Chicche (tutte in v1)

### 2.1 Live Activity + Dynamic Island
- Live Activity e Dynamic Island avanzate sono incluse in Solea Plus.

### 2.2 Widget
- Widget home e lock screen: UV attuale, burn risk, limite prudente rimanente per il proprio fototipo.

### 2.3 Vitamina D + HealthKit
- Stima vitamina D sintetizzata per sessione (f(UV, pelle esposta, durata, fototipo)).
- Scrittura su Apple Health: *Time in Daylight* solo su azione dell'utente. La vitamina D resta una stima in-app e non viene scritta su HealthKit.

### 2.4 Foto-diario del tan
- Feature Solea Plus.
- Selfie periodici in condizioni di luce guidate (overlay di allineamento).
- Confronto prima/dopo con slider e timeline dell'evoluzione del tono.
- Analisi locale del tono pelle (Vision/CoreImage, nessun upload).

### 2.5 Tan planner vacanze
- Feature Solea Plus.
- Inserisci meta e date: previsioni UV della località e **piano di esposizione graduale** giorno per giorno per arrivare alla vacanza con tempi e SPF stimati.

### 2.6 Apple Watch companion
- UV a colpo d'occhio e timer base al polso restano gratuiti; haptic e metriche
  avanzate sono Solea Plus.

### 2.7 Consigli SPF dinamici
- "Oggi UV 8: per il tuo fototipo usa SPF 50, riapplica ogni 90 minuti." Suggerimenti contestuali su quando e cosa applicare.

### 2.8 Modalità lettino/solarium
- Tracking separato per sessioni indoor con potenza lampade e durata; conteggia nella dose UV cumulativa.

### 2.9 Idratazione & after-sun
- Promemoria per bere acqua durante le sessioni lunghe e per il doposole la sera
  dopo una giornata di esposizione (Plus).

### 2.10 Streak e badge
- Streak di "esposizione intelligente" (giorni con sessioni senza superare la soglia di rischio).
- Badge: prima sessione, 7 giorni di streak, tan planner completato, 10.000 IU di vitamina D, ecc.

### 2.11 Coach Solare AI (ibrido on-device + Claude)
- Feature Solea Plus.

Un coach conversazionale che conosce il contesto dell'utente (fototipo, UV attuale, storico sessioni, piano vacanze) e risponde a domande tipo *"posso espormi oggi alle 14 senza crema?"*.

**Architettura ibrida — due livelli con router:**

| Livello | Motore | Casi d'uso | Costo |
|---|---|---|---|
| **On-device** | Apple Foundation Models (iOS 26+) | Briefing mattutino, tip contestuali rapidi, frasi delle notifiche, Q&A semplici, modalità offline | Zero, privato, offline |
| **Cloud** | Claude (`claude-opus-4-8` via proxy) | Chat multi-turno, domande complesse, generazione del piano vacanze personalizzato, spiegazioni dei dati | API a consumo |

**Router:** decide il livello in base a complessità della richiesta, disponibilità del modello on-device (device/iOS version) e connettività. Fallback: on-device → Claude se la richiesta è troppo complessa; Claude → on-device se offline.

**Proxy minimale** (Cloudflare Worker / Vercel function, ~50 righe):
- Custodisce la API key (mai nel binario iOS).
- Inietta il system prompt del coach (statico, con `cache_control` per il prompt caching → ~90% di risparmio sui token ripetuti) + il contesto utente inviato dall'app.
- Streaming SSE verso l'app.
- Rate limit per utente (es. 10 messaggi Claude/giorno, illimitati on-device) per tenere i costi sotto controllo in un'app gratuita.

**Privacy:** al proxy arriva solo il contesto minimo necessario (fototipo, UV, riepilogo sessioni) — mai le foto del tan né dati identificativi. Se il proxy non è configurato, il Coach Plus mostra lo stato non disponibile.

## 2.12 Monetizzazione StoreKit

- Prodotti iniziali in App Store Connect:
  - `com.davidecapurro.Solea.plus.annual`: auto-renewable subscription, prezzo
    indicativo `€19,99/anno`.
  - `com.davidecapurro.Solea.plus.seasonal`: non-renewing subscription,
    prezzo indicativo `€9,99`, accesso app-side di 120 giorni.
  - `com.davidecapurro.Solea.plus.monthly`: definito a codice per eventuale
    test o futura offerta, non promosso nel paywall iniziale (`€3,99/mese`).
- Nessun pagamento esterno: le feature digitali Plus si acquistano e ripristinano
  solo con StoreKit/In-App Purchase.

---

## 3. Social leggero (senza backend custom)

- **Game Center**: classifiche tra amici (minuti di sole intelligenti della settimana, streak più lunga) e achievement nativi — zero gestione account.
- **Share card**: immagine generata (streak, badge, progresso tan)
  condivisibile su Instagram/WhatsApp, feature Plus.
- **CloudKit**: sync dei dati tra dispositivi dell'utente (iPhone/Watch/iPad) via iCloud privato.
- Privacy: le foto del tan restano sempre locali/iCloud privato, mai condivise automaticamente.

---

## 4. Architettura tecnica

| Componente | Tecnologia |
|---|---|
| UI | SwiftUI, iOS 17+ |
| Dati UV/meteo | WeatherKit |
| Posizione | CoreLocation |
| Persistenza | SwiftData + CloudKit sync |
| Timer in background | Live Activities (ActivityKit) + notifiche locali |
| Widget | WidgetKit |
| Salute | HealthKit |
| Watch | watchOS app + WidgetKit complications |
| Foto/analisi tono | AVFoundation + Vision/CoreImage (on-device) |
| Social | GameKit (Game Center) |
| Coach AI on-device | Apple Foundation Models framework (iOS 26+) |
| Coach AI cloud | Claude API (`claude-opus-4-8`) dietro proxy serverless (Cloudflare Worker) |

### Modello dati (bozza)
- `SkinProfile`: fototipo, risposte quiz, MED base.
- `TanSession`: inizio/fine, posizione, UV campionati, SPF, zone esposte, tipo (sole/lettino), dose UV, vitamina D stimata.
- `TanPhoto`: data, immagine, tono medio rilevato.
- `VacationPlan`: meta, date, piano giornaliero generato.
- `Badge` / `Streak`: progressi gamification.

### Mappa schermate
1. **Oggi** (home): UV ora, burn risk, golden hours, CTA "Inizia sessione".
2. **Sessione**: timer, countdown sicurezza, promemoria.
3. **Diario**: storico, statistiche, foto-diario con slider.
4. **Planner**: piani vacanza.
5. **Profilo**: fototipo, badge, classifiche Game Center, impostazioni.

---

## 5. Roadmap di sviluppo

| Milestone | Contenuto |
|---|---|
| **M1 — Fondamenta** | Progetto Xcode, profilo pelle + quiz, UV via WeatherKit, schermata Oggi |
| **M2 — Sessioni** | Timer, calcolo limite prudente, promemoria, diario base |
| **M3 — Sistema** | Live Activity, widget, notifiche, HealthKit Time in Daylight + vitamina D in-app |
| **M4 — Chicche** | Foto-diario, tan planner, lettino, idratazione |
| **M5 — Social & Watch** | Game Center, share card, app Watch, badge/streak |
| **M6 — Coach AI** | Coach on-device (Foundation Models), poi proxy Claude + router ibrido e chat completa |

---

## 6. Disclaimer

L'app fornisce stime informative, non consigli medici. Onboarding con disclaimer chiaro e link alle linee guida OMS sull'esposizione solare.
