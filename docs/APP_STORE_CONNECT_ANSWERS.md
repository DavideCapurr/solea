# App Store Connect answers draft

Bozza operativa aggiornata al 23 giugno 2026. Verifica sempre in App Store Connect prima dell'invio, soprattutto se cambi `CoachConfiguration.proxyURL`, capability, prodotti In-App Purchase o flussi dati.

## Export Compliance

- `ITSAppUsesNonExemptEncryption`: `false` in `App/Info.plist`.
- Risposta consigliata: l'app non usa crittografia proprietaria o non esente. Usa solo API e protocolli standard della piattaforma quando i servizi Apple sono usati dall'utente.
- Se in futuro abiliti il proxy cloud del coach, rivaluta questa sezione prima della submission.

## App Privacy

Tracking:

- Tracking: No.
- Third-party advertising: No.
- Data broker / cross-app tracking: No.

Data types per build corrente:

- Location: usata per App Functionality. Serve a recuperare indice UV/meteo e calcolare limiti prudenziali. Non tracking.
- Health & Fitness: usata per App Functionality. Solea scrive opzionalmente Time in Daylight in Apple Health; non legge dati HealthKit. La vitamina D resta una stima in-app e non viene scritta su HealthKit.
- Photos or Videos: foto selezionate dall'utente per il diario locale. Non caricate su server Solea.
- Gameplay Content / Game Center: classifiche e traguardi gestiti tramite Game Center se l'utente è autenticato.
- Purchases: StoreKit verifica acquisto e ripristino di Solea Plus. Nessun pagamento esterno e nessun tracking.

Da non dichiarare nella build corrente:

- Contact Info: non raccolta dall'app.
- Identifiers raccolti da Solea: no, finché `CoachConfiguration.proxyURL = nil`.
- Usage Data / Diagnostics raccolti da Solea: no.
- Sensitive Info raccolte da Solea: no.

## Regulated Medical Device

- Risposta consigliata: No.
- Motivazione: Solea fornisce stime informative e limiti prudenziali per esposizione solare, non diagnosi, terapia, monitoraggio medico o trattamento. La UI e la descrizione App Store devono mantenere il disclaimer "non consigli medici".

## Age Rating

Risposte consigliate per il questionario:

- Cartoon/Fantasy Violence: None.
- Realistic Violence: None.
- Prolonged Graphic or Sadistic Realistic Violence: None.
- Profanity or Crude Humor: None.
- Mature/Suggestive Themes: None.
- Horror/Fear Themes: None.
- Medical/Treatment Information: Infrequent/Mild, perché l'app parla di pelle, UV, HealthKit e vitamina D in modo informativo.
- Alcohol, Tobacco, or Drug Use or References: None.
- Simulated Gambling: None.
- Sexual Content or Nudity: None.
- Graphic Sexual Content and Nudity: None.
- Contests: No.
- Gambling: No.
- Unrestricted Web Access: No.
- User-Generated Content: No.

## Critical Alerts

- Capability richiesta: `com.apple.developer.usernotifications.critical-alerts`.
- Uso dichiarato: solo per l'avviso locale di arresto quando il limite prudente di esposizione è esaurito.
- Non usare Critical Alerts per marketing, engagement o promemoria generici.

## In-App Purchase

- Le feature digitali Solea Plus devono essere acquistabili solo tramite In-App
  Purchase/StoreKit.
- Prodotti iniziali:
  - `com.davidecapurro.Solea.plus.annual`: auto-renewable subscription,
    prezzo indicativo `€19,99/anno`.
  - `com.davidecapurro.Solea.plus.seasonal`: non-renewing subscription,
    prezzo indicativo `€9,99`, accesso app-side di 120 giorni.
  - `com.davidecapurro.Solea.plus.monthly`: opzionale/non promosso nel paywall
    iniziale, prezzo indicativo `€3,99/mese`.
- Includi localizzazioni, screenshot se richiesti da App Store Connect e sottoponi
  gli IAP alla review insieme alla build.

## Review Notes

Usa il testo in `docs/APP_STORE_METADATA.md`, sezione `Review notes`.

Includi anche:

- Il coach cloud è disabilitato nella build corrente (`CoachConfiguration.proxyURL = nil`).
- HealthKit è usato solo per la scrittura opzionale di Time in Daylight.
- Critical Alerts sono limitate allo stop alert di sicurezza.
- Game Center deve avere classifiche e traguardi già creati in App Store Connect.
- I prodotti In-App Purchase di Solea Plus devono essere creati in App Store
  Connect e disponibili in sandbox prima della review.
