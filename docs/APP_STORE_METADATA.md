# App Store metadata draft

Bozza operativa per creare la scheda App Store Connect di Solea.

## Nome e categoria

- Nome app: Solea
- Sottotitolo: UV, SPF e diario solare
- Categoria primaria: Salute e fitness
- Categoria secondaria: Lifestyle
- Prezzo: gratuita con In-App Purchase per Solea Plus

## Testi prodotto

### Promotional text

Tempi di esposizione personalizzati in base a fototipo, UV reale e sessioni già svolte, con timer, diario locale e Solea Plus opzionale.

### Description

Solea ti aiuta ad abbronzarti in modo più consapevole, con stime prudenti basate su fototipo e UV.

Imposta il tuo fototipo con un quiz guidato, controlla l'indice UV reale della tua zona e avvia sessioni con durata, SPF e promemoria suggeriti. Durante la sessione Solea tiene traccia del tempo effettivo al sole, delle pause, del bilanciamento fronte/retro e della dose UV stimata.

Puoi consultare il diario delle sessioni, seguire i tuoi progressi, stimare la vitamina D, usare widget, sincronizzare il fototipo con Apple Watch e salvare opzionalmente su Apple Health il tempo alla luce del giorno.

Solea Plus sblocca planner vacanze, coach AI cloud quando configurato, foto-diario prima/dopo, statistiche storiche, reminder personalizzati, Watch/Live Activity avanzati e share card premium. Gli acquisti e il ripristino passano sempre da In-App Purchase dell'App Store.

Solea fornisce stime informative, non consigli medici. Per dubbi sulla pelle, farmaci fotosensibilizzanti o condizioni dermatologiche, consulta un medico o un dermatologo.

### Keywords

abbronzatura,protezione,spf,vitamina,pelle,meteo,salute,estate,raggi,diario,fototipo

## Review notes

Solea usa WeatherKit per l'indice UV e le previsioni, Core Location per i calcoli locali basati sulla posizione corrente, StoreKit per Solea Plus, HealthKit solo su azione dell'utente per scrivere Time in Daylight, Game Center per classifiche e traguardi e notifiche locali per i promemoria di sessione.

Solea Plus usa due prodotti promossi nel paywall: annuale auto-rinnovabile (`com.davidecapurro.Solea.plus.annual`, prezzo indicativo €19,99/anno) e Summer Pass non-rinnovabile (`com.davidecapurro.Solea.plus.seasonal`, prezzo indicativo €9,99, accesso app-side di 120 giorni). Il prodotto mensile `com.davidecapurro.Solea.plus.monthly` è definito a codice ma non promosso nella UI iniziale.

Solea richiede Critical Alerts per l'avviso di sicurezza quando il limite prudente di esposizione è esaurito. Nel codice questo avviso usa `UNNotificationSound.defaultCritical`; gli altri promemoria usano suoni standard. Critical Alerts non vengono usate per marketing, coinvolgimento o promemoria ricorrenti.

Il coach cloud è disabilitato nella build corrente (`SoleaCoachProxyURL` vuoto); il codice usa solo il motore on-device quando disponibile. Le foto del diario restano sul dispositivo e non vengono caricate su server.

## Privacy label draft

Verifica sempre in App Store Connect prima della pubblicazione. Per la build corrente:

- Location: usata per App Functionality, non tracking. Serve a richiedere UV/meteo e calcolare limiti di esposizione.
- Health & Fitness: usata per App Functionality, non tracking. Solea scrive opzionalmente Time in Daylight su Apple Health; non legge dati HealthKit. La vitamina D resta una stima in-app e non viene scritta su HealthKit.
- Photos or Videos: le foto del diario sono selezionate dall'utente e restano locali. Non sono caricate su server.
- Purchases: Solea usa StoreKit per verificare l'accesso a Solea Plus. Nessun pagamento esterno o tracking.
- Gameplay Content / Game Center activity: leaderboard e achievement passano tramite Game Center se l'utente è autenticato.
- Identifiers: l'ID anonimo del coach cloud resta inutilizzato finché `SoleaCoachProxyURL` è vuoto; aggiorna questa sezione se abiliti il proxy.

Tracking: no.

Risposte dettagliate per App Privacy, Export Compliance e Age Rating: `docs/APP_STORE_CONNECT_ANSWERS.md`.

## Screenshot checklist

- iPhone 6.9": Oggi, Sessione attiva, Diario, Planner, Profilo.
- iPhone 6.3": opzionale se vuoi controllare rendering su display medio.
- Apple Watch: UV, timer sessione, picker fototipo.

Dimensioni e shot list dettagliate: `docs/APP_STORE_SCREENSHOTS.md`.

Usa dati dimostrativi realistici e nessuna foto personale identificabile.
