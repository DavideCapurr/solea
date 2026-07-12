Tracking:

- Tracking: No.
- Third-party advertising: No.
- Data broker / cross-app tracking: No.

Data types per build corrente:

- Location: usata per App Functionality. Serve a recuperare indice UV/meteo e calcolare limiti prudenziali. Non tracking.
- Health & Fitness: usata per App Functionality. Tanora scrive opzionalmente Time in Daylight in Apple Health; non legge dati HealthKit. La vitamina D resta una stima in-app e non viene scritta su HealthKit.
- Photos or Videos: foto selezionate dall'utente per il diario locale. Non caricate su server Tanora.
- Gameplay Content / Game Center: classifiche e traguardi gestiti tramite Game Center se l'utente è autenticato.
- Purchases: StoreKit verifica acquisto e ripristino di Tanora Plus. Nessun pagamento esterno e nessun tracking.

Da non dichiarare nella build corrente:

- Contact Info: non raccolta dall'app.
- Identifiers raccolti da Tanora: no, finché `SoleaCoachProxyURL` è vuoto.
- Usage Data / Diagnostics raccolti da Tanora: no.
- Sensitive Info raccolte da Tanora: no.
