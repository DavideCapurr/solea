# Decisione LLM per il Coach Solare

Aggiornato: 2026-06-23

## Decisione

Il Coach AI di Solea resta ibrido:

1. Apple Foundation Models on-device e' il primo livello quando disponibile: zero token cost, offline, dati locali.
2. Il cloud passa attraverso un proxy serverless provider-agnostic, mai direttamente dall'app.
3. Il default cloud scelto e' Gemini 2.5 Flash-Lite: resta molto economico, ha una buona piattaforma developer e bilancia meglio costo/qualita' rispetto al minimo assoluto.
4. Mistral `ministral-3b-latest` resta disponibile come fallback di costo minimo; Anthropic Claude Sonnet 4.6 resta un fallback premium configurabile.
5. Apple Private Cloud Compute e' la direzione preferita appena diventa praticabile per Solea: mantiene una postura privacy-first e non richiede API key developer, ma dipende da dispositivi Apple Intelligence, disponibilita' e limiti giornalieri utente.

## Principi

- Il modello non calcola soglie UV, MED, burn risk o raccomandazioni numeriche critiche: queste restano in `SoleaCore`.
- Al cloud arriva solo il contesto minimo: fototipo, UV, riepilogo sessioni e messaggi chat. Mai foto, dati HealthKit grezzi, posizione precisa o identificativi personali.
- Il client iOS parla sempre con lo stesso formato SSE del proxy. Cambiare provider non deve richiedere una modifica della chat SwiftUI.
- Ogni provider cloud deve avere rate limit lato server e secret solo su Cloudflare.

## Confronto sintetico

| Opzione | Ruolo consigliato | Motivo |
|---|---|---|
| Apple Foundation Models on-device | Default locale | Privacy, offline, zero costo; adatto a risposte brevi e contestuali |
| Apple Private Cloud Compute | Upgrade Apple-first | Modello server piu' capace con privacy Apple e senza token cost developer |
| Gemini 2.5 Flash-Lite | Default cloud scelto | Economico e piu' equilibrato per qualita'/piattaforma rispetto al minimo assoluto |
| Mistral `ministral-3b-latest` | Fallback di costo minimo | Prezzo text-to-text piu' basso tra le opzioni chat valutate |
| OpenAI `gpt-5.4-mini` | Alternativa qualita'/tooling | Buon compromesso, ma piu' caro di Gemini Flash-Lite |
| Anthropic Claude Sonnet 4.6 | Fallback premium | Buona qualita' conversazionale; piu' caro di Gemini e OpenAI mini |
| Mistral Large / Small | Alternative Mistral piu' capaci | Costano piu' di Ministral 3B; da usare solo se gli eval mostrano qualita' insufficiente |

## Fonti primarie consultate

- OpenAI API models e pricing: https://developers.openai.com/api/docs/models e https://openai.com/api/pricing/
- Anthropic models e pricing: https://platform.claude.com/docs/en/about-claude/models/overview e https://platform.claude.com/docs/en/about-claude/pricing
- Gemini API models/pricing: https://ai.google.dev/gemini-api/docs/models e https://ai.google.dev/gemini-api/docs/pricing
- Mistral models/pricing: https://docs.mistral.ai/models/overview e https://mistral.ai/pricing/
- Apple Foundation Models e Private Cloud Compute: https://developer.apple.com/machine-learning/whats-new/ e https://developer.apple.com/videos/play/wwdc2026/319/

## Prossimi passi

1. Configurare `GEMINI_API_KEY` come secret Cloudflare e deployare il proxy.
2. Aggiungere una suite di eval minimale per il coach: tono, limiti medici, non-invenzione di numeri, rispetto del contesto Solea.
3. Valutare Apple Private Cloud Compute appena il progetto passa a Xcode/iOS 26 come baseline di sviluppo per le feature AI avanzate.
