# Meme "Niche mfs" (TikTok / Reels)

Asset per il remix del meme sun-burn → seed-oils, riadattato a Solea.

## Formato del meme

- **Parte 1 (setup):** caption in alto `"I'm sunburnt i was in the sun for too long"`,
  foto di una scottatura, overlay `Dumb mfs:`.
- **Parte 2 (punchline):** la caption originale `The real reason:` diventa **`Niche mfs:`**
  e al posto della foto degli oli di semi va una foto che rappresenta Solea.

I "niche mfs" sono quelli che invece di scottarsi usano Solea per abbronzarsi smart.

## File

Le `panel_*` sono **1060×1310 px**, esattamente lo slot foto del video (larghezza piena,
da `y=367` a `y=1677` su un frame 1060×2298): si trascinano dentro senza ridimensionare.
I `mockup_*` mostrano il frame finito con la caption `Niche mfs:`.

| File | Concept |
|---|---|
| `panel_A_app.png` | Un solo screen dell'app (Solea Check) su gradiente caldo. Letterale: "ecco l'app". |
| `panel_B_three.png` | Tre screen a ventaglio (sessione live, Solea Check, diario). Più "flex": prodotto vero. |
| `panel_C_brand.png` | Logo + wordmark `Solea` con tagline `tan smart. don't burn.` Minimal. |
| `mockup_A/B/C.png` | Anteprima full-frame (1060×2298) con caption `Niche mfs:`. |

## Sorgenti

Composti da asset già nel repo:
- screenshot App Store `AppStore/Screenshots/iPhone-6.9/`
- icona app `App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- palette brand: sunset orange `#FF9E1A` + crema.

Rigenerabili con lo script di composizione (Pillow): vedi cronologia PR.
