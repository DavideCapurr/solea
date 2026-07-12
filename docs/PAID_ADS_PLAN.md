# Tanora — Piano sponsorizzazioni (estate 2026)

Aggiornato: 2026-07-10

Obiettivo: spingere download durante le settimane di picco estivo con budget
piccolo e controllato, senza rompere la postura privacy dell'app ("Data Not
Collected": nessun SDK di tracking in-app).

## Principio guida

Con Tanora Plus a €19,99/anno e Summer Pass a €9,99, e una conversione
free→paid realistica del 2-5%, un install "vale" indicativamente €0,30-0,90.
Nessun canale paid è ROI-positivo a questi numeri nel breve: il budget va
trattato come **investimento di momentum estivo con un tetto fisso**, non
come macchina da profitto. Tetto consigliato per luglio+agosto: **€400-600
totali**. Quando finiscono, si valuta con i dati.

## Ordine di partenza (pre-flight, prima di spendere)

1. **`SoleaAppStoreURL`** valorizzato in `project.yml` (fatto:
   `https://apps.apple.com/it/app/solea/id6782854851`, link id-based che
   sopravvive al rename) → serve inviare la release che lo contiene.
2. **Nuovi metadata inviati in App Store Connect** (nome "Tanora: tan
   timer e UV", sottotitolo "Abbronzatura uniforme, diario", keywords):
   gli annunci Apple Ads usano la scheda così com'è; con la scheda vecchia
   la conversione è più bassa. Il rename in App Information richiede che il
   nome "Tanora" sia libero su App Store Connect: verificarlo al momento
   dell'invio.
3. **Custom Product Page** in App Store Connect per il traffico TikTok
   (screenshot in ordine tan-first: timer fronte/retro, UV live, diario
   prima/dopo). Il link della CPP va in bio TikTok: così in App Analytics
   distingui il traffico TikTok da tutto il resto.

## Canale 1 — Apple Ads (Search Ads): il primo euro va qui

Perché per primo: intercetta **intento di ricerca** ("abbronzatura",
"indice uv") nel momento di picco stagionale, non richiede SDK né cambi
alle privacy label, attribuzione nativa nella dashboard Apple.

Setup (ads.apple.com, account con lo stesso Apple ID sviluppatore):

- Campagne **Advanced** (controllo keyword e CPT massimo), storefront
  **Italia**, poi eventualmente ES/FR/DE/PT visto che l'app è localizzata.
- Budget: **€5-8/giorno** con tetto mensile. CPT massimo iniziale: €0,50-1,00.
- Struttura a 3 campagne:

### Campagna Brand (difesa, budget minimo)

Exact match: `tanora`, `tanora app`, `tanora tan timer`
(più `solea` finché il rename non è live, per chi ha visto la scheda vecchia)

### Campagna Generica (il cuore, ~70% del budget)

Exact match, da incollare:

```
abbronzatura
abbronzatura app
abbronzarsi
tintarella
indice uv
uv index
uv oggi
tan timer
timer abbronzatura
abbronzatura perfetta
abbronzatura uniforme
vitamina d sole
solarium
```

Broad match parallela a CPT più basso (€0,30) per scoprire query nuove:
`abbronzatura`, `sole uv`, `tan`.

### Campagna Competitor (~20% del budget)

Exact match sui nomi che l'utente cerca già (lecito su Apple Ads):

```
sola app
sola uv
bronzy
indice uv abbronzatura
uv lens
sun index
```

Regole di gestione (10 minuti ogni 2-3 giorni):

- Keyword con >€8 spesi e 0 install → pausa.
- Keyword con install a CPA < €1,50 → alza CPT del 20%.
- Dopo 2 settimane: sposta budget sulle 3-5 keyword migliori.
- Le query emerse dalla broad match che convertono → exact match dedicata.

## Canale 2 — TikTok Promote (amplificazione, non semina)

Promote (il boost dentro l'app TikTok) non richiede SDK e si paga con
monete/€ direttamente dal telefono. Regola ferrea, già nel piano organico:

> Si boosta **solo un post che sta già andando** (salvataggi/share sopra la
> media del canale nelle prime 24-48h). Mai per rianimare un post morto.

- Obiettivo: **"Visite al sito web"** con il link App Store (o CPP), non
  follower né visualizzazioni.
- Taglio: **€10-15 per boost**, durata 3 giorni, max 2 boost/settimana.
- Pubblico: automatico (l'algoritmo sa già chi ha reagito al post).
- Misura: tap sul link in Promote + picco "Web Referrer" in App Analytics
  nei 3 giorni del boost.

## Canale 3 — TikTok Ads Manager / Spark Ads (solo dopo, se serve scalare)

Le campagne App Install vere su TikTok Ads Manager richiedono TikTok SDK o
un MMP (AppsFlyer/Adjust) + SKAdNetwork nell'app. Questo:

- cambia le privacy nutrition label ("Data Not Collected" salta);
- aggiunge lavoro di integrazione e review;
- ha senso solo con budget >€1.000/mese e una conversione Plus provata.

Alternativa senza SDK: campagne **Traffico** verso la CPP con **Spark Ads**
(si sponsorizza un post organico tuo o di un creator con il suo permesso).
Attribuzione solo via App Analytics (product page views della CPP), quindi
imprecisa: accettabile per test da €50-100, non oltre.

Nota policy: TikTok vieta ads su servizi di abbronzatura indoor/solarium in
vari mercati. Un tan timer/app UV è ammesso, ma nelle creative sponsorizzate
evitare claim tipo "abbronzatura sicura" o riferimenti a lettini: restare su
timer, UV live, diario, tan uniforme.

## Creator seeding (budget parallelo, spesso il migliore)

Con gli stessi €100-200 di un test ads si pagano 3-5 micro-creator italiani
(10-50k follower, beach/skincare/lifestyle) per un post "How I tan" col
brief già pronto in `docs/TIKTOK_VIRAL_PLAN.md` (sezione Creator brief,
ancora valido). Chiedere sempre l'autorizzazione Spark Ads nel accordo:
se il post funziona, si boosta quello.

## Misurazione senza SDK (tutta in App Store Connect + Apple Ads)

| Cosa | Dove |
|---|---|
| Install e spesa per keyword | Dashboard Apple Ads |
| Download da ricerca vs web vs referrer | App Analytics → Sources |
| Traffico TikTok (bio/Promote) | App Analytics → la Custom Product Page dedicata |
| Conversione scheda (view → install) | App Analytics → Conversion Rate |
| Ricavi Plus | App Store Connect → Trends |

Controllo settimanale (lunedì, 15 minuti): spesa totale, install per
canale, CPA per canale, trial/acquisti Plus. Se dopo 3 settimane il CPA
Apple Ads resta sopra €2 e la conversione scheda sotto il 3%, il problema è
la **product page** (screenshot/subtitle), non il budget: fermare la spesa
e sistemare quella.

## Riepilogo budget consigliato

| Canale | Budget | Quando |
|---|---|---|
| Apple Ads | €150-200/mese (€5-8/giorno) | Da subito |
| TikTok Promote | €80-120/mese (2 boost/sett.) | Dal primo post con trazione |
| Creator seeding | €100-200 una tantum | Settimana 2-3 |
| TikTok Ads Manager | 0 per ora | Solo se Plus converte e serve scala |
