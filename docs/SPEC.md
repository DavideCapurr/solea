# ☀️ Solea — Specifica di prodotto v1

> App iOS per abbronzarsi al meglio, senza scottarsi. **Tan-first, ma smart.**

- **Filosofia**: l'obiettivo dell'utente è un'abbronzatura bella e uniforme; l'app lo aiuta a raggiungerla in modo intelligente e sicuro. Tono motivazionale, non medicale.
- **Prezzo**: completamente gratuita, nessun paywall.
- **Piattaforma**: iOS 17+, SwiftUI, companion Apple Watch.
- **Backend**: nessun server custom — WeatherKit, Game Center e CloudKit coprono tutto.

---

## 1. Funzionalità core

### 1.1 UV in tempo reale
- Indice UV attuale dalla posizione GPS (WeatherKit).
- Previsioni UV orarie (oggi) e giornaliere (7 giorni) con grafico della curva.
- **Golden hours**: fasce orarie evidenziate in cui il rapporto abbronzatura/rischio è ottimale per il fototipo dell'utente.
- Indicatore **burn risk** live a semaforo (verde/giallo/rosso) che combina UV attuale, tempo già esposto oggi e SPF applicato.

### 1.2 Profilo pelle
- Onboarding con quiz fototipo (scala Fitzpatrick I–VI): tono pelle, colore occhi/capelli, lentiggini, reazione tipica al sole.
- Da fototipo + UV + SPF l'app calcola il **tempo di esposizione sicura** (basato su MED — Minimal Erythema Dose — per fototipo).
- Il profilo è modificabile e si raffina nel tempo con i dati delle sessioni.

### 1.3 Sessione di abbronzatura (timer)
- Avvio sessione con scelta SPF applicato e zone esposte (fronte/retro, viso, gambe…).
- Countdown del tempo sicuro rimanente, ricalcolato se l'UV cambia.
- Promemoria **"girati!"** a intervalli configurabili per un tan uniforme.
- Promemoria **riapplica la crema** (ogni 2h o dopo il bagno, configurabile).
- Alert di stop all'avvicinarsi della soglia di rischio scottatura.
- A fine sessione: riepilogo (durata, UV medio, dose UV stimata, vitamina D stimata).

### 1.4 Diario e statistiche
- Storico sessioni con durata, UV medio, SPF, dose UV cumulativa.
- Statistiche settimanali/mensili: tempo totale al sole, trend, giorni di streak.
- Dose UV cumulata della giornata sempre visibile (somma di più sessioni).

---

## 2. Chicche (tutte in v1)

### 2.1 Live Activity + Dynamic Island
- La sessione attiva vive nella Dynamic Island e in Live Activity sulla lock screen: countdown, UV attuale, prossimo promemoria.

### 2.2 Widget
- Widget home e lock screen: UV attuale, burn risk, tempo sicuro rimanente per il proprio fototipo.

### 2.3 Vitamina D + HealthKit
- Stima vitamina D sintetizzata per sessione (f(UV, pelle esposta, durata, fototipo)).
- Scrittura su Apple Health: *Time in Daylight* e vitamina D; lettura opzionale per arricchire le statistiche.

### 2.4 Foto-diario del tan
- Selfie periodici in condizioni di luce guidate (overlay di allineamento).
- Confronto prima/dopo con slider e timeline dell'evoluzione del tono.
- Analisi locale del tono pelle (Vision/CoreImage, nessun upload).

### 2.5 Tan planner vacanze
- Inserisci meta e date: previsioni UV della località e **piano di esposizione graduale** giorno per giorno per arrivare alla vacanza già preparato e abbronzarsi senza scottature.

### 2.6 Apple Watch companion
- Timer al polso, haptic per "girati" e "riapplica crema", UV a colpo d'occhio, avvio sessione dal polso.

### 2.7 Consigli SPF dinamici
- "Oggi UV 8: per il tuo fototipo usa SPF 50, riapplica ogni 90 minuti." Suggerimenti contestuali su quando e cosa applicare.

### 2.8 Modalità lettino/solarium
- Tracking separato per sessioni indoor con potenza lampade e durata; conteggia nella dose UV cumulativa.

### 2.9 Idratazione & after-sun
- Promemoria per bere acqua durante le sessioni lunghe e per il doposole la sera dopo una giornata di esposizione.

### 2.10 Streak e badge
- Streak di "esposizione intelligente" (giorni con sessioni senza superare la soglia di rischio).
- Badge: prima sessione, 7 giorni di streak, tan planner completato, 10.000 IU di vitamina D, ecc.

### 2.11 Coach Solare AI (ibrido on-device + Claude)

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

**Privacy:** al proxy arriva solo il contesto minimo necessario (fototipo, UV, riepilogo sessioni) — mai le foto del tan né dati identificativi.

---

## 3. Social leggero (senza backend custom)

- **Game Center**: classifiche tra amici (minuti di sole intelligenti della settimana, streak più lunga) e achievement nativi — zero gestione account.
- **Share card**: immagine generata (streak, badge, progresso tan) condivisibile su Instagram/WhatsApp.
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
| **M2 — Sessioni** | Timer, calcolo esposizione sicura, promemoria, diario base |
| **M3 — Sistema** | Live Activity, widget, notifiche, HealthKit + vitamina D |
| **M4 — Chicche** | Foto-diario, tan planner, lettino, idratazione |
| **M5 — Social & Watch** | Game Center, share card, app Watch, badge/streak |
| **M6 — Coach AI** | Coach on-device (Foundation Models), poi proxy Claude + router ibrido e chat completa |

---

## 6. Disclaimer

L'app fornisce stime informative, non consigli medici. Onboarding con disclaimer chiaro e link alle linee guida OMS sull'esposizione solare.
