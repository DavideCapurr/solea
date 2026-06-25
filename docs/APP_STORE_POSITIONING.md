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

## 7. Gap attuali da chiudere prima di candidarsi

| Priorità | Gap | Riferimento |
|---|---|---|
| Alta | Icona app è un placeholder | `App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` |
| Alta | Audit accessibilità (VoiceOver, Dynamic Type) | tutta la UI in `App/Features/` |
| Alta | Asset product page (preview video + screenshot) | da produrre (vedi `docs/ASSETS.md`) |
| Media | Estendere localizzazione oltre l'italiano | `App/Resources/Localizable.xcstrings` |
| Media | Verifica supporto day-one ultimo iOS e design di sistema | progetto |
| Bassa | Privacy nutrition labels in App Store Connect | configurazione store |

---

## 8. Checklist sintetica di candidatura

- [ ] Release stabile e testata pubblicata (o in fase di review) con anticipo
- [ ] Tecnologie Apple in evidenza nel pitch
- [ ] Product page completa (icona, preview, screenshot, testo)
- [ ] Accessibilità e localizzazione verificate
- [ ] Privacy labels corrette
- [ ] Nomination inviata via App Store Connect 3–4 settimane prima del target
- [ ] Timing allineato alla stagione estiva / a un evento (WWDC, lancio iOS)
