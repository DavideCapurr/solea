# Solea TikTok slideshow sprint

Aggiornato: 2026-06-24

Priorita': slideshow/photo-mode prima, video dopo. Per Solea e' il formato piu'
veloce da testare perche' trasforma UV, fototipo, SPF, mare/piscina/vacanza e
timer in contenuti salvabili.

Asset generati:

- `Marketing/TikTok/slideshows/01-mare-uv-8`
- `Marketing/TikTok/slideshows/02-checklist-prima-del-sole`
- `Marketing/TikTok/slideshows/03-piscina`

Rigenerazione:

```sh
node scripts/render-tiktok-slideshows.mjs
```

## Perche' slideshow first

- Piu' veloce: non serve girare ogni volta.
- Piu' salvabile: checklist, mini-guide e confronti funzionano bene a slide.
- Piu' commentabile: ogni carousel puo' chiudere con "commenta fototipo + UV".
- Piu' riusabile: lo stesso impianto diventa video solo se prende.
- Piu' coerente con Solea: il valore e' decisionale, non solo estetico.

## Regole creative

Formato:

- 1080 x 1920, verticale.
- 6-8 slide per post.
- Una sola idea per slide.
- Testo grande, poche parole, niente paragrafi.
- Slide 1 = hook forte.
- Slide 2 = situazione reale.
- Slide 3-5 = Solea ragiona.
- Penultima = decisione concreta.
- Ultima = CTA commentabile.

Layout:

- Titolo grande in alto.
- Screenshot/app card al centro.
- Nota breve in basso.
- Lascia margini per UI TikTok.
- Mai testo minuscolo.
- Usare sempre lo stesso sistema visivo: sole/arancio, nero, bianco, screenshot
  app, micro-icone.

Sound:

- Usare audio trend leggero o suono estivo soft.
- Lo slideshow deve funzionare anche senza audio.
- Evitare audio meme se rende medico/salute troppo frivolo.

Guardrail:

- Non dire "abbronzatura sicura".
- Non dire "zero rischi".
- Non dire "non ti scotti".
- Non incentivare peak UV, no SPF o scottatura.
- Usare formule come "stima informativa", "limite prudente", "non consiglio
  medico" quando serve.

## Template base

Slide 1: hook

> Giornata al mare, UV 8: prima faccio questo.

Slide 2: situazione

> Sabbia, acqua, vento. Perdi il conto in 20 minuti.

Slide 3: input

> Solea guarda UV + fototipo + SPF.

Slide 4: decisione

> Timer prima di stendermi.

Slide 5: reminder

> Acqua, lato, SPF, stop.

Slide 6: CTA

> Commenta "mare" + fototipo e faccio il tuo Solea Check.

## Slideshow 1: giornata al mare, UV 8

Obiettivo: far diventare il Solea Check un gesto da spiaggia.

Slide-by-slide:

1. "Giornata al mare, UV 8: prima faccio questo."
2. "Errore classico: stendersi e andare a sensazione."
3. "Solea Check: UV reale, fototipo, SPF."
4. "Se l'UV e' alto, il timer cambia."
5. "Non e' solo durata: lato, acqua, riapplica SPF."
6. "Obiettivo: abbronzatura smart, non pelle arrossata."
7. "Commenta MARE + fototipo e faccio un esempio."

Caption:

> Prima di stendermi: UV, fototipo, SPF, timer. Stima informativa, non consiglio
> medico.

Commento fissato:

> Che UV c'e' oggi dove sei?

## Slideshow 2: giornata in piscina

Obiettivo: posizionare Solea come anti-perdita-del-conto.

Slide-by-slide:

1. "Piscina: la scottatura arriva quando pensi di essere stato poco."
2. "Un tuffo. Due chiacchiere. Un altro lettino."
3. "Il sole intanto non mette pausa da solo."
4. "Solea: avvio sessione, poi pausa se entro in acqua/ombra."
5. "Reminder SPF: perche' il 'dopo lo faccio' e' una bugia estiva."
6. "Team mare o team piscina?"
7. "Commenta PISCINA e preparo il prossimo check."

Caption:

> La piscina sembra piu' controllata, ma e' facilissimo perdere il conto.

Commento fissato:

> Team mare o piscina?

## Slideshow 3: primo giorno di vacanza

Obiettivo: usare una tensione emotiva molto condivisibile.

Slide-by-slide:

1. "Primo giorno di vacanza: non recuperi tre mesi in un pomeriggio."
2. "Il rischio non e' amare il sole. E' partire troppo forte."
3. "Solea parte da meta, date, UV e fototipo."
4. "Giorno 1: piano piu' graduale."
5. "Golden hours > picco UV."
6. "Diario serale: cosa ho fatto, come sta la pelle."
7. "Il tan buono non rovina il giorno 2."
8. "Commenta la tua meta."

Caption:

> Il primo giorno decide il tono della vacanza. Letteralmente e non solo.

Commento fissato:

> Dove vai quest'estate?

## Slideshow 4: nuvoloso traditore

Obiettivo: contenuto educativo e salvabile.

Slide-by-slide:

1. "Nuvoloso non vuol dire UV zero."
2. "Il cielo sembra tranquillo."
3. "La pelle pero' non legge le nuvole. Riceve UV."
4. "Solea controlla il dato, non la vibe."
5. "Se l'UV conta: SPF, timer, ombra."
6. "Salva per la prossima giornata grigia."

Caption:

> Il meteo non basta. Prima di esporti, guarda l'UV.

Commento fissato:

> Ti sei mai scottato con il cielo coperto?

## Slideshow 5: stesso sole, fototipi diversi

Obiettivo: spiegare la personalizzazione in modo immediato.

Slide-by-slide:

1. "Stesso sole. Tre fototipi. Tre timer diversi."
2. "Fototipo II: margine piu' stretto."
3. "Fototipo IV: piano diverso, non rischio zero."
4. "Fototipo VI: cambia ancora."
5. "Poi entra SPF, UV reale e tempo gia' preso oggi."
6. "Copiare la routine dell'amica non e' una strategia."
7. "Commenta FOTOTIPO e faccio parte 2."

Caption:

> Stessa spiaggia non significa stessa esposizione. Stima informativa, non
> consiglio medico.

Commento fissato:

> Parte 2: SPF 30 vs SPF 50?

## Slideshow 6: cosa controllo prima del sole

Obiettivo: checklist super salvabile.

Slide-by-slide:

1. "Prima di prendere sole controllo 5 cose."
2. "1. UV reale, non solo temperatura."
3. "2. Fototipo."
4. "3. SPF che metto davvero."
5. "4. Quanto sole ho gia' preso oggi."
6. "5. Come sta la pelle: bene, calda, tira, rossa."
7. "Questo e' il Solea Check."
8. "Salva per la prossima spiaggia."

Caption:

> La checklist che avrei voluto prima di mille "ancora 10 minuti".

Commento fissato:

> Quale punto salti piu' spesso?

## Slideshow 7: la pelle tira

Obiettivo: mettere in scena una decisione prudente senza tono medico.

Slide-by-slide:

1. "Se la pelle tira, il piano cambia."
2. "Non e' una vibe. E' un segnale fisico."
3. "In Solea seleziono: Bene / Calda / Tira / Rossa."
4. "Se tira: meno sole, piu' ombra, recupero."
5. "Se e' rossa: niente sole diretto oggi."
6. "Il tan non si forza quando il corpo ha gia' parlato."
7. "Stima informativa, non consiglio medico."

Caption:

> La schermata che vorrei aprire prima di dire "ancora un po'".

Commento fissato:

> Ti capita piu' "calda" o "tira"?

## Slideshow 8: SPF non cancella il tan

Obiettivo: rispondere a un'obiezione commentabile.

Slide-by-slide:

1. "SPF non significa: niente abbronzatura."
2. "SPF significa: il piano cambia."
3. "Solea mette SPF dentro il timer."
4. "Senza SPF: limite prudente piu' breve."
5. "Con SPF: gestione diversa, non invincibilita'."
6. "Il punto non e' evitare l'estate. E' non improvvisarla."
7. "Commenta SPF e faccio parte 2."

Caption:

> SPF non e' un interruttore estate/off. E' un input del piano.

Commento fissato:

> SPF 30 o 50: cosa usi davvero?

## Slideshow 9: golden hours, non peak UV

Obiettivo: spostare il desiderio dal picco UV alle ore intelligenti.

Slide-by-slide:

1. "Il momento migliore non e' per forza il picco UV."
2. "Peak UV = piu' aggressivo, non piu' furbo."
3. "Solea cerca le ore ideali per il tuo fototipo."
4. "Guarda UV, rischio, durata e obiettivo."
5. "Risultato: finestre piu' sensate."
6. "Golden hours > tanmaxxing."
7. "Vuoi il check della tua citta'?"

Caption:

> Non cercare solo "quando picchia di piu'". Cerca quando ha piu' senso.

Commento fissato:

> Citta' + fototipo e faccio un esempio.

## Slideshow 10: weekend corto

Obiettivo: parlare al comportamento "ho solo due giorni".

Slide-by-slide:

1. "Weekend al mare: il piano non e' 'piu' sole possibile'."
2. "Sabato: sei carico."
3. "Domenica: vuoi recuperare tutto."
4. "Lunedi': non vuoi pagare il conto."
5. "Solea conta anche il sole gia' preso oggi."
6. "Timer + SPF + diario."
7. "Il tan furbo non rovina il rientro."
8. "Commenta WEEKEND per il piano."

Caption:

> Due giorni bastano per fare bene o per esagerare. Io scelgo timer.

Commento fissato:

> Weekend al mare o in piscina?

## Slideshow 11: giornata in barca

Obiettivo: scenario aspirazionale + rischio percepito basso.

Slide-by-slide:

1. "In barca non senti il caldo. L'UV pero' c'e'."
2. "Vento + acqua = ti senti fresco."
3. "Il sole intanto continua."
4. "Solea Check prima di partire."
5. "SPF alto, timer, acqua, ombra quando puoi."
6. "Questo e' il check da barca."
7. "Commenta BARCA se vuoi il template."

Caption:

> In barca il timer e' ancora piu' utile, proprio perche' non senti tutto.

Commento fissato:

> Barca, sup o pedalo'?

## Slideshow 12: sole in citta'

Obiettivo: allargare Solea oltre mare/piscina.

Slide-by-slide:

1. "Non serve essere al mare per prendere UV."
2. "Pausa pranzo."
3. "Camminata."
4. "Terrazzo."
5. "Viso e braccia contano comunque."
6. "Solea Check anche in citta'."
7. "Salva se vivi di 'solo 20 minuti fuori'."

Caption:

> Solea non e' solo app da vacanza. Il sole succede anche nel quotidiano.

Commento fissato:

> Dove prendi piu' sole senza accorgertene?

## Sequenza di pubblicazione: primi 7 giorni

Priorita': 2 slideshow al giorno. Video solo se hai gia' asset pronti.

| Giorno | Slideshow 1 | Slideshow 2 | Video opzionale |
|---|---|---|---|
| D1 | Giornata al mare, UV 8 | Cosa controllo prima del sole | Beach Mode con sabbia sulle mani |
| D2 | Giornata in piscina | SPF non cancella il tan | Reply a commento SPF |
| D3 | Primo giorno di vacanza | Golden hours, non peak UV | Planner vacanza |
| D4 | Nuvoloso traditore | Stesso sole, fototipi diversi | Same beach video |
| D5 | Weekend corto | La pelle tira | Founder: no "abbronzatura sicura" |
| D6 | Giornata in barca | Sole in citta' | Watch / timer al polso |
| D7 | Best commenti settimana | Top 5 errori prima del sole | Recap parlato |

## Slideshow KPI

Valutare dopo 24h e 72h:

- Views.
- Like rate.
- Save rate.
- Share rate.
- Commenti per 1.000 views.
- Qualita' commenti: chiedono fototipo, meta, SPF, uscita app?
- Follower gained.
- Profile visits.
- Link/App Store taps, quando disponibile.

Decisione:

- Save alto: farne una serie checklist.
- Share alto: rifarlo con scenario piu' specifico.
- Commenti alti: fare reply slideshow e poi video.
- Completion/swipe-through debole: ridurre testo e slide.
- Views basse ma saves alti: ripubblicare con hook piu' diretto.

## Da trasformare in video

Solo gli slideshow che vincono diventano video. Regola:

- Top 3 per commenti: video reply.
- Top 3 per saves: video tutorial.
- Top 3 per shares: video POV giornata.

Il primo video non deve essere perfetto. Deve nascere da una slide che ha gia'
dimostrato interesse.
