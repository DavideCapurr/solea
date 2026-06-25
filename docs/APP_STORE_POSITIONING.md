# 🏆 Solea — Strategia per il feature nella tab "Oggi" dell'App Store

> Come posizionare Solea per essere messa in evidenza (featured) dal team
> editoriale di Apple, in particolare nella tab **Oggi** dell'App Store.

La tab "Oggi" è curata **editorialmente**: Apple non promuove le app per
download o ranking, ma sceglie a mano quelle che **mostrano le sue tecnologie**,
hanno design eccellente e raccontano una storia. Solea parte avvantaggiata
perché tocca quasi tutto l'ecosistema. Questo documento traduce quel vantaggio
in un piano operativo.

---

## 1. Perché Solea è un buon candidato

| Leva editoriale | Come Solea la soddisfa |
|---|---|
| **Showcase di tecnologie Apple** | WeatherKit, Live Activities + Dynamic Island, WidgetKit, HealthKit, Apple Watch, Game Center, CloudKit, Vision/CoreImage, **Apple Foundation Models** (AI on-device, iOS 26+) |
| **Privacy-first** | Foto e analisi del tono restano on-device; al proxy AI arriva solo il contesto minimo |
| **Gratis, zero paywall** | Storia editoriale "no catch" pulita |
| **Stagionalità** | Sole = primavera/estate: timing naturale per le collection estive |
| **Angolo narrativo chiaro** | "Tan-first, ma smart" — benessere stagionale, non medicale |
| **Tono di sistema** | SwiftUI nativo, integrazione profonda con iOS/watchOS |

---

## 2. Calendario stagionale (la leva più importante)

Il feature va **richiesto in anticipo** rispetto al momento in cui si vuole
essere in vetrina. Per un'app solare, l'onda è l'estate dell'emisfero nord.

| Quando | Azione |
|---|---|
| **Fine inverno (feb–mar)** | Inviare la nomination di featuring puntando all'estate |
| **Primavera (apr–mag)** | Release pronta, product page rifinita, supporto day-one dell'ultimo iOS |
| **Inizio estate (giu)** | Finestra ideale per le collection "estate / benessere stagionale" |
| **WWDC (giu)** | Se si usano API nuove (es. Foundation Models), candidarsi come esempio della tecnologia dell'anno |

> Regola pratica: candidarsi con **3–4 settimane di anticipo** rispetto alla
> data target di messa in evidenza.

---

## 3. Come candidarsi

Apple **non** scopre le app da sola in modo affidabile: bisogna proporsi.

1. **Form ufficiale di nomination** in App Store Connect
   (*Featuring → Nominate your app for featuring*).
   Compilare con: novità rilevanti, tecnologie Apple usate, eventi/stagionalità,
   localizzazioni, accessibilità.
2. **Guidare il pitch con le tecnologie Apple**: in cima Dynamic Island/Live
   Activity, Foundation Models on-device, Apple Watch, WeatherKit. È ciò che gli
   editor cercano per le collection "How we made it" e tematiche.
3. **Tempistica**: inviare per ogni release/stagione rilevante (vedi §2).

---

## 4. Mappa tecnologie Apple → angolo editoriale

| Tecnologia | Collection / storia in cui può entrare |
|---|---|
| Apple Foundation Models (on-device) | "App realizzate con l'AI on-device", esempi WWDC |
| Live Activity + Dynamic Island | "App che sfruttano la Dynamic Island" |
| Apple Watch companion | "Le migliori app per Apple Watch" |
| HealthKit + vitamina D | "Salute & benessere" |
| WidgetKit | "Widget che amiamo" |
| Privacy on-device (Vision/CoreImage) | Storie su privacy e on-device intelligence |
| Stagionalità sole | "App per la tua estate" |

---

## 5. Requisiti non negoziabili dell'editoriale

Apple esclude app che non superano questi controlli, a prescindere dalla bontà
dell'idea:

- [ ] **Accessibilità**: VoiceOver completo, Dynamic Type, contrasto adeguato,
      label sui controlli.
- [ ] **Localizzazione**: più lingue = più mercati feature-abili
      (base già presente in `App/Resources/Localizable.xcstrings`).
- [ ] **Design HIG impeccabile** e adozione dell'ultimo linguaggio di sistema
      (es. Liquid Glass) con **supporto day-one** del nuovo iOS.
- [ ] **Qualità tecnica**: zero crash, avvio rapido, gestione pulita degli
      errori (es. fallback WeatherKit con retry già previsto).
- [ ] **Privacy nutrition labels** accurate e coerenti con il claim
      "niente upload delle foto".

---

## 6. Product page (è parte del prodotto)

Gli editor valutano anche la pagina. Da curare come asset di prima classe:

- [ ] **Icona app distintiva** — *gap attuale*: `App/Resources/Assets.xcassets/AppIcon.appiconset` è ancora un placeholder.
- [ ] **App preview video** (15–30s): sessione live nella Dynamic Island, widget, Apple Watch.
- [ ] **Screenshot progettati** con didascalie (non semplici cattura schermo);
      almeno uno con Live Activity e uno con il Watch.
- [ ] **Testo descrizione** che apre con l'angolo "Tan-first, ma smart" e le
      tecnologie Apple.
- [ ] **Keyword/categoria** coerenti (Salute e fitness / Stile di vita).

---

## 7. Gap di codice da chiudere prima di candidarsi

Audit dello stato attuale del repository (verificato sul codice, non stime).
Ogni voce ha riscontro, riferimento di file e azione concreta.

### 7.1 Icona app mancante — **bloccante**

`App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` dichiara un
solo slot `1024x1024` **senza la chiave `filename`**: non esiste alcun file
immagine, l'icona è un placeholder vuoto. Senza icona non si supera la review,
men che meno un feature.

```jsonc
// stato attuale: nessun "filename" → nessuna immagine
{ "idiom": "universal", "platform": "ios", "size": "1024x1024" }
```

- **Azione**: aggiungere il PNG 1024×1024 (senza alpha, angoli quadrati) e il
  riferimento `"filename"` nel `Contents.json`. Per il look "moderno" iOS valutare
  l'asset stratificato (`.icon` / Icon Composer) per il rendering Liquid Glass.

### 7.2 Accessibilità: zero copertura — **alta priorità**

Ricerca su tutto `App/`: **0 occorrenze** di `accessibilityLabel`,
`accessibilityValue`, `accessibilityHint`, `accessibilityElement`,
`dynamicTypeSize` o qualunque modificatore `.accessibility*`. L'accessibilità è
un criterio esplicito di selezione editoriale, quindi va colmata in modo mirato:

- **Valori dinamici → `accessibilityLabel` + `accessibilityValue`**: UV attuale,
  countdown sessione, dose UV. Es. in `App/Features/Today/TodayView.swift` e
  `App/Features/Session/ActiveSessionView.swift`.
- **Semaforo burn risk**: già corretto — `TodayView.swift:148` usa `Label`
  (testo + icona `circle.fill`), quindi **non** è un segnale solo-colore.
  Aggiungere solo un `accessibilityLabel` esplicito col livello.
- **Grafico UV** (`TodayView.swift`): fornire un riassunto testuale
  (`accessibilityLabel`) perché il grafico non è leggibile da VoiceOver.
- **Dynamic Type**: l'icona/numero UV usa `.frame(width: 90, height: 90)` fisso
  (`TodayView.swift:143`); verificare che non tagli il testo alle taglie
  accessibili (usare `minimumScaleFactor`/`ScaledMetric` o layout flessibile).
- **Foto-diario** (`App/Features/Diary/PhotoDiaryView.swift`): label per gli
  overlay di allineamento e per lo slider prima/dopo.

### 7.3 Localizzazione limitata — **media priorità**

`App/Resources/Localizable.xcstrings`: sorgente `it`, **249 chiavi**, un'unica
lingua aggiunta (`en`). Più lingue = più mercati in cui Apple può fare feature.

- **Azione**: aggiungere almeno ES, FR, DE, PT (mercati solari/turistici).
  Verificare anche le stringhe dei target Watch/Widget e dei testi delle
  notifiche generate dal coach.

### 7.4 Gestione errori a prova di demo — **media priorità**

WeatherKit/posizione devono fallire in modo pulito (già previsto da spec con
retry). Prima della candidatura, verificare gli stati di errore in
`App/Services/LocationService.swift` e nel flusso UV di
`App/Features/Today/TodayViewModel.swift` (nessuno schermo bianco, sempre un CTA
"Riprova").

### 7.5 Altri controlli non di codice

| Priorità | Gap | Dove |
|---|---|---|
| Alta | Asset product page (preview video + screenshot) | produrre, vedi `docs/ASSETS.md` |
| Media | Supporto day-one ultimo iOS e design di sistema | configurazione progetto / `project.yml` |
| Bassa | Privacy nutrition labels | App Store Connect |

### 7.6 Definition of Done della "parte di codice" — stato

- [x] Icona 1024×1024 presente e referenziata nel `Contents.json`
      (`icon-1024.png`, sole su gradiente tramonto, RGB senza alpha)
- [x] `accessibilityLabel`/`Value` su tutti i valori dinamici chiave (UV, countdown, dose)
      — `TodayView.swift`, `ActiveSessionView.swift`
- [x] Riassunto testuale del grafico UV per VoiceOver (`forecastSummary`, label per barra)
- [x] Almeno 4 lingue oltre IT/EN in `Localizable.xcstrings` (ES, FR, DE, PT: 255/255 chiavi)
- [x] EN completato (era 242/255 → 255/255)
- [x] Stati di errore WeatherKit/posizione con retry verificati (`LocationError` tipizzato,
      `ContentUnavailableView` + "Riprova", warning non bloccanti) — già robusti, nessuna modifica
- [ ] Layout alle taglie Dynamic Type accessibili da verificare a runtime su device/simulatore

> Tutti i gap di codice di questa sezione sono stati implementati sul branch
> `claude/solea-app-store-positioning-x4sxym`. Restano voci che richiedono
> Xcode/dispositivo (verifica Dynamic Type a runtime) o azioni fuori dal codice (§7.5).

---

## 8. Checklist sintetica di candidatura

- [ ] Release stabile e testata pubblicata (o in fase di review) con anticipo
- [ ] Tecnologie Apple in evidenza nel pitch
- [ ] Product page completa (icona, preview, screenshot, testo)
- [ ] Accessibilità e localizzazione verificate
- [ ] Privacy labels corrette
- [ ] Nomination inviata via App Store Connect 3–4 settimane prima del target
- [ ] Timing allineato alla stagione estiva / a un evento (WWDC, lancio iOS)
