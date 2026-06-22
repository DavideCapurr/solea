# App Store Connect answers draft

Bozza operativa aggiornata al 17 giugno 2026. Verifica sempre in App Store Connect prima dell'invio, soprattutto se cambi `CoachConfiguration.proxyURL`, capability o flussi dati.

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
- Gameplay Content / Game Center: leaderboard e achievement gestiti tramite Game Center se l'utente e' autenticato.

Da non dichiarare nella build corrente:

- Contact Info: non raccolta dall'app.
- Identifiers raccolti da Solea: no, finche' `CoachConfiguration.proxyURL = nil`.
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
- Medical/Treatment Information: Infrequent/Mild, perche' l'app parla di pelle, UV, HealthKit e vitamina D in modo informativo.
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
- Uso dichiarato: solo stop alert locale quando il limite prudente di esposizione e' esaurito.
- Non usare Critical Alerts per marketing, engagement o promemoria generici.

## Review Notes

Usa il testo in `docs/APP_STORE_METADATA.md`, sezione `Review notes`.

Includi anche:

- Il coach cloud e' disabilitato nella build corrente (`CoachConfiguration.proxyURL = nil`).
- HealthKit e' solo scrittura opzionale di Time in Daylight.
- Critical Alerts sono limitate allo stop alert di sicurezza.
- Game Center deve avere leaderboard e achievement gia' creati in App Store Connect.
