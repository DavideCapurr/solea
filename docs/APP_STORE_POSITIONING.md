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

## 7. Gap di codice — stato post-merge con `main`

I gap di codice originari sono stati chiusi (in parte da questo lavoro, in parte
da `main`, che ha portato l'intero pacchetto App Store: metadata, screenshot,
privacy manifest, localizzazione Watch/Widget). Stato attuale verificato:

### 7.1 Icona app — ✅ risolto

`App/Resources/Assets.xcassets/AppIcon.appiconset/` referenzia `AppIcon-1024.png`
(icona reale fornita da `main`) tramite `"filename"` nel `Contents.json`.
Nessun placeholder.

### 7.2 Accessibilità — ✅ coperta sui punti chiave

`accessibilityLabel`/`Value` su valori dinamici e grafico UV:

- **UV / burn risk** in `TodayView.swift` (gauge e semaforo, che è un `Label`
  testo + icona, non un segnale solo-colore).
- **Grafico UV**: riassunto testuale per VoiceOver (`forecastSummary`) + label e
  valore per ogni barra.
- **Dose UV** in `ActiveSessionView.swift` (`doseRing` con label + percentuale).
- **Modalità spiaggia / story** (da `main`): `accessibilityHint` sui CTA.

### 7.3 Localizzazione — ✅ completa in 6 lingue (App + Watch + Widget)

`App/Resources/Localizable.xcstrings`: sorgente `it`, **456 chiavi** tradotte al
100% in **IT, EN, ES, FR, DE, PT** (456/456 per lingua). Parità dei format
specifier (`%@`, `%lld`, `%%`) verificata.

I target **Watch** e **Widget** sono allineati: `WatchApp/{it,en,es,fr,de,pt}.lproj/`
contiene sia `Localizable.strings` (12 chiavi runtime: dose UV, controlli sessione,
errori posizione) sia `InfoPlist.strings` (display name + `NSLocationWhenInUseUsageDescription`).
`Widgets/{it,en,es,fr,de,pt}.lproj/InfoPlist.strings` localizza il display name del
widget (le label runtime arrivano da `Localizable.xcstrings` condiviso). `project.yml`
dichiara esplicitamente `knownRegions: [it, en, es, fr, de, pt]` così Xcode riconosce
tutte le lingue indipendentemente da quali file siano presenti.

### 7.4 Gestione errori — ✅ robusta

`LocationError` tipizzato/localizzato, `ContentUnavailableView` con "Riprova",
warning non bloccanti in `TodayViewModel`/`SessionManager`. Nessuna modifica
necessaria.

### 7.5 Dynamic Type — ✅ verificato a `accessibility-XXXL`

Build su `iPhone 17 Pro / iOS 26.4` (Xcode 26.4.1) e screenshot di tutte le tab
con `xcrun simctl ui … content_size accessibility-extra-extra-extra-large`.
Trovati e corretti due eyebrow label che si spezzavano char-by-char in HStack
con una data accanto:

- [TodayView.swift:205](App/Features/Today/TodayView.swift:205) — `Label("SOLEA CHECK", …)` ora ha `lineLimit(1)` + `minimumScaleFactor(0.7)`.
- [DiaryView.swift:60](App/Features/Diary/DiaryView.swift:60) — `Label("DIARIO SOLEA", …)` idem.

Tab Planner/Coach (paywall Solea Plus) e Profile rendono pulito a XXXL: testo
con wrap a parola, niente clipping. Tab bar resta leggibile.

### 7.6 Build & test — ✅ verde

- `xcodegen generate` → progetto Xcode include 6 lingue note (`Base, de, en, es, fr, it, pt`).
- `xcodebuild -scheme Solea -destination "platform=iOS Simulator,id=iPhone17Pro,OS=26.4" build` → **BUILD SUCCEEDED**.
- `swift test` sul package `SoleaCore` → **63/63 test PASS** (TanPlannerTests, VitaminDTests, SunExposureAdvisorTests, SessionTrackingTests, …).

### 7.7 Privacy nutrition labels — ✅ allineate al manifest

`App/PrivacyInfo.xcprivacy` dichiara `NSPrivacyCollectedDataTypes` vuoto e
`NSPrivacyTracking = false`. La build spedita ha `SOLEA_COACH_PROXY_URL = ""`
([project.yml:79](project.yml:79)), quindi nessun dato lascia il dispositivo
verso server Solea. WeatherKit / HealthKit / Game Center sono servizi
Apple-managed e non costituiscono "data collected by Solea" secondo la
definizione Apple.

[`AppStore/Metadata/{it,en,es,fr,de,pt}/app_privacy.md`](AppStore/Metadata/it/app_privacy.md)
ora dichiarano coerentemente **Data Not Collected** con spiegazione per ogni
categoria potenzialmente sollevata da App Store Connect (Location, Health &
Fitness, Photos, Game Center, Identifiers). Include la procedura per riallineare
manifest + nutrition labels se in una release futura il proxy del coach verrà
abilitato.

> **Quando si invia su App Store Connect**, nel questionario "App Privacy"
> rispondere: *Tracking* → No; *Data Collection* → "No, we do not collect data
> from this app". Coerente al 100% con il manifest spedito.

### 7.8 Controlli residui

Nessuno bloccante. Voci di follow-up opzionali (post-release):

- Estensione delle altre metadata App Store (description.txt, keywords.txt,
  promotional_text.txt, ecc.) a ES/FR/DE/PT — al momento solo IT/EN sono
  presenti in `AppStore/Metadata/`.

> Nota: `main` include già `docs/APP_STORE_METADATA.md`, `APP_STORE_SUBMISSION.md`,
> screenshot e script di preflight. Questo documento resta la **vista editoriale**
> (perché/quando/come candidarsi al feature), complementare a quei runbook operativi.

---

## 8. Checklist sintetica di candidatura

- [ ] Release stabile e testata pubblicata (o in fase di review) con anticipo
- [ ] Tecnologie Apple in evidenza nel pitch
- [ ] Product page completa (icona, preview, screenshot, testo)
- [ ] Accessibilità e localizzazione verificate
- [ ] Privacy labels corrette
- [ ] Nomination inviata via App Store Connect 3–4 settimane prima del target
- [ ] Timing allineato alla stagione estiva / a un evento (WWDC, lancio iOS)
