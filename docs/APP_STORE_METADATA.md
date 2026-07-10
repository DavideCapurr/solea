# App Store metadata draft

Bozza operativa per creare la scheda App Store Connect di Solea.

## Nome e categoria

- Nome app: Solea: abbronzatura smart
- Sottotitolo: Tan timer, UV live e diario
- Categoria primaria: Salute e fitness
- Categoria secondaria: Lifestyle
- Prezzo: gratuita con In-App Purchase per Solea Plus

## Testi prodotto

### Promotional text

Quanto sole ti serve oggi per il tuo tan? UV live, timer fronte/retro e diario: costruisci un'abbronzatura più uniforme, che dura di più. L'estate non aspetta.

### Description

Solea è il tan timer che costruisce la tua abbronzatura con metodo: più uniforme, più costante, senza andare a sensazione. UV reale, fototipo e timer fronte/retro al posto delle improvvisazioni.

Imposta il tuo fototipo con un quiz guidato, controlla l'indice UV reale della tua zona e avvia sessioni con durata, SPF e promemoria suggeriti. Durante la sessione Solea tiene traccia del tempo effettivo al sole, delle pause, del bilanciamento fronte/retro e della dose UV stimata.

Puoi consultare il diario delle sessioni, seguire i tuoi progressi, stimare la vitamina D, usare widget, sincronizzare il fototipo con Apple Watch e salvare opzionalmente su Apple Health il tempo alla luce del giorno.

Solea Plus sblocca planner vacanze, coach AI cloud quando configurato, foto-diario prima/dopo, statistiche storiche, reminder personalizzati, Watch/Live Activity avanzati e share card premium. Gli acquisti e il ripristino passano sempre da In-App Purchase dell'App Store.

Solea fornisce stime informative, non consigli medici. Per dubbi sulla pelle, farmaci fotosensibilizzanti o condizioni dermatologiche, consulta un medico o un dermatologo.

Informativa privacy: https://davidecapurr.github.io/solea/privacy/
Termini d'uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

> Solea usa l'EULA standard di Apple: lasciala come default in App Store Connect (nessun EULA custom) e tieni il link nella App Description. Imposta il campo **Privacy Policy URL** → `https://davidecapurr.github.io/solea/privacy/`.

### Keywords

tintarella,abbronzarsi,sole,spf,estate,mare,piscina,fototipo,vitamina d,scottatura,solarium

(la parola "abbronzatura" vive già nel nome e "tan timer"/"UV" nel sottotitolo: non
va ripetuta nelle keywords, Apple indicizza nome + sottotitolo + keywords insieme)

## Review notes

Solea usa WeatherKit per l'indice UV e le previsioni, Core Location per i calcoli locali basati sulla posizione corrente, StoreKit per Solea Plus, HealthKit solo su azione dell'utente per scrivere Time in Daylight, Game Center per classifiche e traguardi e notifiche locali per i promemoria di sessione.

Solea Plus usa due prodotti promossi nel paywall: annuale auto-rinnovabile (`com.davidecapurro.Solea.plus.annual`, prezzo indicativo €19,99/anno) e Summer Pass non-rinnovabile (`com.davidecapurro.Solea.plus.seasonal`, prezzo indicativo €9,99, accesso app-side di 120 giorni). Il prodotto mensile `com.davidecapurro.Solea.plus.monthly` è definito a codice ma non promosso nella UI iniziale.

Solea NON usa Critical Alerts e non richiede l'entitlement `com.apple.developer.usernotifications.critical-alerts`. Tutti i promemoria e l'avviso di sicurezza al raggiungimento del limite prudente di esposizione sono notifiche locali standard (`[.alert, .sound]`, `UNNotificationSound.default`); l'utente può disattivarle in Impostazioni iOS.

Il coach cloud è disabilitato nella build corrente (`SoleaCoachProxyURL` vuoto); il codice usa solo il motore on-device quando disponibile. Le foto del diario restano sul dispositivo e non vengono caricate su server.

### Risposte ai rilievi della review precedente

Da incollare nel campo **Notes** della sezione App Review Information (testo completo in `AppStore/Metadata/{it,en}/review_notes.txt`):

- **3.1.2(c) EULA**: paywall Solea Plus con titolo/durata/prezzo + link funzionanti a Termini d'uso (EULA standard Apple) e Informativa privacy; stessi link in Profilo > Informazioni; EULA standard Apple linkata anche nella descrizione App Store.
- **1.4.1 Citazioni**: schermata "Fonti scientifiche" (Profilo > Informazioni) con link a OMS, EPA, FDA, NIH ODS, DermNet, ICNIRP, CIE; raggiungibile anche dai disclaimer in Oggi, Onboarding, Coach.
- **5.1.1(v) Eliminazione account**: Profilo > Account > "Elimina account e dati" (wipe completo dei dati locali + reset onboarding).
- **5.2.5 WeatherKit**: marchio "Apple Weather" + link legale (`https://weather-data.apple.com/legal-attribution.html`) sotto il grafico "Previsione UV" in Oggi e nel dettaglio piano del Planner.

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
