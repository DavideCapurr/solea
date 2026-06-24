# Solea TikTok assets

Asset pronti per testare slideshow/photo-mode su TikTok.

## Primo batch

Cartella: `Marketing/TikTok/slideshows`

Carousel generati:

1. `01-mare-uv-8`
   - 7 slide PNG 1080 x 1920.
   - Caption: `Prima di stendermi: UV, fototipo, SPF, timer. Stima informativa, non consiglio medico.`
   - Commento fissato: `Che UV c'e' oggi dove sei?`
2. `02-checklist-prima-del-sole`
   - 8 slide PNG 1080 x 1920.
   - Caption: `La checklist che avrei voluto prima di mille "ancora 10 minuti".`
   - Commento fissato: `Quale punto salti piu' spesso?`
3. `03-piscina`
   - 7 slide PNG 1080 x 1920.
   - Caption: `La piscina sembra piu' controllata, ma e' facilissimo perdere il conto.`
   - Commento fissato: `Team mare o piscina?`

Carica i PNG in ordine numerico dentro ogni cartella.

## Rigenerare

```sh
node scripts/render-tiktok-slideshows.mjs
```

Lo script rigenera SVG sorgenti e PNG finali in `Marketing/TikTok/slideshows`.

## Priorita' di pubblicazione

1. `01-mare-uv-8`
2. `02-checklist-prima-del-sole`
3. `03-piscina`

Pubblica i primi due nello stesso giorno se possibile: uno situazionale e uno
checklist. Il terzo va bene come test del giorno dopo o come secondo post se i
primi commenti parlano di piscina.
