# Game Center setup

Setup operativo per creare i componenti Game Center di Solea in App Store
Connect. Gli ID qui sotto devono combaciare esattamente con il codice; non
rinominarli dopo averli creati.

Fonte Apple consultata il 17 giugno 2026: App Store Connect Help, "Submit Game
Center components".

## Leaderboards

| Leaderboard ID | Nome consigliato | Score format | Ordinamento | Note |
| --- | --- | --- | --- | --- |
| `solea.weekly.smart.minutes` | Minuti smart settimanali | Integer | Higher is better | Minuti di esposizione prudenziale nella settimana corrente. |
| `solea.longest.streak` | Streak piu' lunga | Integer | Higher is better | Giorni consecutivi di esposizione intelligente. |

## Achievements

| Achievement ID | Titolo | Descrizione | Punti suggeriti | Hidden |
| --- | --- | --- | --- | --- |
| `firstSession` | Prima sessione | Hai completato la tua prima sessione. | 10 | No |
| `weekStreak` | 7 giorni smart | Sette giorni di fila di esposizione intelligente. | 25 | No |
| `plannerCompleted` | Vacanza preparata | Hai completato un piano di preparazione vacanza. | 25 | No |
| `vitaminD10k` | 10.000 IU di vitamina D | Hai accumulato 10.000 IU di vitamina D stimata. | 40 | No |

Totale punti suggerito: 100.

## Submission

- Crea leaderboard e achievement prima di inviare la build con Game Center
  attivo.
- Alla prima submission con Game Center, includi i componenti nella stessa
  submission dell'app version.
- Dopo aver creato tutto in App Store Connect, aggiorna
  `docs/APP_STORE_EXTERNAL_FIELDS.md` impostando `Game Center components:
  created`.
