# Tanora TikTok assets

Direzione aggiornata (2026-07-10): tan-first puro, niente ottica salutista.
Il piano operativo e' [`docs/TIKTOK_TAN_TREND_PLAN.md`](../../docs/TIKTOK_TAN_TREND_PLAN.md).

## Regola d'oro

I PNG sintetici in `slideshows/` sono un **fallback**, non il formato
principale. Il formato principale e': foto vere scattate con l'iPhone
(mare, piscina, lettino, crema, lino) + testo aggiunto con l'editor nativo
di TikTok + screenshot dell'app solo alla slide 3-4. Il post deve sembrare
di una persona, non di un brand.

Le foto vere vanno in `backgrounds/<deck-id>/<slide>.jpg` (cartella oggi
vuota: riempirla e' il primo passo del piano).

## Deck copy (fallback sintetico)

Il copy dei deck vive in `scripts/render-tiktok-slideshows.mjs` ed e'
allineato al piano tan-first:

1. `01-primo-giorno-di-mare` — "Il primo giorno di mare decide tutta la tua estate."
2. `02-abbronzatura-a-chiazze` — "Il motivo per cui ti abbronzi a chiazze."
3. `03-golden-tan-hours` — "L'orario in cui ti abbronzi meglio non e' quello che pensi."
4. `04-base-tan-vacanza` — "Base tan in 7 giorni prima della partenza."
5. `05-piscina-vs-mare` — "Piscina o mare per abbronzarsi? Facciamo i conti."
6. `06-diario-tan-30-giorni` — "Ho tracciato la mia abbronzatura per 30 giorni: risultati."

La prima slide di ogni deck e' solo hook: nessun header brand (regola
tan-first, il brand entra dalla slide 2).

## Rigenerare (solo su Mac)

```sh
node scripts/render-tiktok-slideshows.mjs
```

Attenzione: lo script **cancella e ricrea** `Marketing/TikTok/slideshows/`
e converte SVG→PNG con `sips`/`qlmanage` (solo macOS). I PNG attualmente
committati vengono da una generazione precedente (copy vecchio): vanno
rigenerati prima di usarli come fallback.

## Priorita' di pubblicazione

Seguire il calendario 14 giorni in `docs/TIKTOK_TAN_TREND_PLAN.md`:
si parte con "How I tan" su foto vere, non con i deck sintetici.
