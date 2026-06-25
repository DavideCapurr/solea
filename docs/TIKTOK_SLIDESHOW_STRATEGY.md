# Solea TikTok slideshow strategy

Aggiornato: 2026-06-25

Direzione: tan-first, marketing velato, old money/resort aesthetic.

Solea non deve sembrare un contenuto sulla protezione dal sole. Deve sembrare un
contenuto utile per abbronzarsi meglio: piu' uniforme, piu' tracciabile, piu'
metodico. Il mood deve essere old money: resort, riviera, pool club, linen,
tennis club, calma, luce buona. La protezione resta un guardrail, non il gancio
creativo.

## Regola principale

Struttura 70/30:

- 70% vibe mare/piscina/vacanza + utility per abbronzarsi.
- 30% Solea, inserita a meta' slideshow come strumento naturale.

Non iniziare con "scarica Solea" o "questa app". Iniziare con una situazione:

- giornata al mare;
- lettino in piscina;
- voglio un tan uniforme;
- parto tra 7 giorni e voglio una base;
- voglio capire quando girarmi.

## Struttura carousel

1. Slide 1: hook tan-first, niente brand.
2. Slide 2: vibe/situazione reale.
3. Slide 3: piccolo problema pratico, ancora niente vendita dura.
4. Slide 4: "qui entra Solea" o "a meta' apro Solea".
5. Slide 5: feature utile: timer, lato, UV, fototipo, diario.
6. Slide 6: beneficio tan: piu' metodo, piu' uniformita', meno caso.
7. Slide 7: comment bait.

## Formato generic/aesthetic

Questo e' il formato prioritario per evitare l'effetto advertising:

- foto o visual full-screen;
- testo grande al centro;
- niente UI app nelle prime slide;
- Solea inserita a meta' carousel;
- product placement trattato come gesto naturale della routine.

## Codice visivo old money

Preferire:

- palette ivory, verde club, navy, oro spento;
- font serif/editoriale;
- bordi sottili, card squadrate, pochi elementi;
- foto verticali con linen, lettini, piscina, ombrellone, tennis club, acqua;
- copy calmo e secco.

Evitare:

- arancione acceso dominante;
- gradienti troppo startup;
- bottoni grandi;
- emoji;
- copy urlato tipo "hack", "segreto", "mai piu'";
- product card troppo pubblicitaria.

Esempio:

1. `routine mare old money`
2. `lino, acqua fredda, lato A`
3. `niente fretta, stesso ritmo`
4. `a meta' apro Solea`
5. `timer fronte / retro`
6. `diario tan a fine giornata`
7. `salva questa routine`

Questo formato deve vivere idealmente sopra foto vere del mare/piscina. Gli
asset generati usano visual full-screen sintetici solo come fallback.

Per usare foto vere, inseriscile qui:

```text
Marketing/TikTok/backgrounds/<deck-id>/<slide-number>.jpg
```

Esempio:

```text
Marketing/TikTok/backgrounds/05-routine-mare-aesthetic/01.jpg
```

## Copy da preferire

- "tan plan"
- "abbronzatura con metodo"
- "abbronzatura uniforme"
- "riviera routine"
- "pool club"
- "linen"
- "resort tan"
- "slow tan"
- "fronte/retro"
- "giornata al mare"
- "piscina routine"
- "base vacanza"
- "diario tan"
- "golden tan hours"

## Copy da evitare come gancio

- "protezione"
- "paura di scottarsi"
- "rischio"
- "allarme"
- "stop"
- "non ti scotti"
- "abbronzatura sicura"

SPF puo' comparire, ma come input pratico del tan plan, non come tema del post.

## Product placement velato

Frasi consigliate:

- "A meta' giornata apro Solea."
- "Qui entra Solea."
- "Lo tengo su Solea, cosi' non vado a memoria."
- "Uso Solea come tan timer."
- "Mi salva il diario tan."

Non usare:

- "La migliore app per..."
- "Devi scaricare..."
- "Solea ti protegge..."
- "Evita scottature..."

## Primo batch asset

Generati da:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
CLANG_MODULE_CACHE_PATH=.swift-module-cache \
SWIFT_MODULE_CACHE_PATH=.swift-module-cache \
xcrun swift scripts/render_tiktok_slideshows.swift
```

Output:

- `Marketing/TikTok/slideshows/01-mare-tan-vibe`
- `Marketing/TikTok/slideshows/02-piscina-tan-routine`
- `Marketing/TikTok/slideshows/03-abbronzatura-uniforme`
- `Marketing/TikTok/slideshows/04-base-vacanza`
- `Marketing/TikTok/slideshows/05-routine-mare-aesthetic`
- `Marketing/TikTok/slideshows/06-routine-piscina-aesthetic`
- `Marketing/TikTok/slideshows/07-tan-uniforme-aesthetic`
