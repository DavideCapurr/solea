# Game Center setup

Setup operativo per creare i componenti Game Center di Solea in App Store
Connect. Gli ID qui sotto devono combaciare esattamente con il codice; non
rinominarli dopo averli creati.

Fonti Apple consultate il 23 giugno 2026: App Store Connect Help, "Manage
leaderboards", "Manage achievements" e "Submit Game Center components".

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

## Passaggi App Store Connect

Apri `Solea` in App Store Connect, poi `Game Center` nella sidebar.

### Leaderboard 1

- Click `Add Leaderboard`.
- Reference name: `Minuti smart settimanali`.
- Leaderboard ID: `solea.weekly.smart.minutes`.
- Type: `Classic Leaderboard`.
- Score format: `Integer`.
- Score order: `Higher is better`.
- Localization `Italiano`:
  - Name: `Minuti smart settimanali`.
  - Score format: integer minutes, unit/suffix `min` se richiesto dal form.

### Leaderboard 2

- Click `Add Leaderboard`.
- Reference name: `Streak piu' lunga`.
- Leaderboard ID: `solea.longest.streak`.
- Type: `Classic Leaderboard`.
- Score format: `Integer`.
- Score order: `Higher is better`.
- Localization `Italiano`:
  - Name: `Streak piu' lunga`.
  - Score format: integer days, unit/suffix `giorni` se richiesto dal form.

### Achievement

Ripeti `Add Achievement` per ogni riga:

| Reference name | Achievement ID | Points | Hidden | Repeatable | Titolo IT | Descrizione IT pre/post |
| --- | --- | ---: | --- | --- | --- | --- |
| `Prima sessione` | `firstSession` | 10 | No | No | `Prima sessione` | `Hai completato la tua prima sessione.` |
| `7 giorni smart` | `weekStreak` | 25 | No | No | `7 giorni smart` | `Sette giorni di fila di esposizione intelligente.` |
| `Vacanza preparata` | `plannerCompleted` | 25 | No | No | `Vacanza preparata` | `Hai completato un piano di preparazione vacanza.` |
| `10.000 IU di vitamina D` | `vitaminD10k` | 40 | No | No | `10.000 IU di vitamina D` | `Hai accumulato 10.000 IU di vitamina D stimata.` |

Usa la stessa descrizione per stato non ottenuto e ottenuto, se App Store
Connect richiede entrambi i campi. Il totale e' 100 punti, sotto il limite Apple
di 1000 punti per app.

Non premere `Submit for Review` dei componenti Game Center da soli per la prima
submission: devono essere inclusi nella stessa submission della versione iOS 1.0.
