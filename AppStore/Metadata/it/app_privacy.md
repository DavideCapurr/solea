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
