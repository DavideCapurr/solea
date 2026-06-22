# Modello scientifico Solea

Solea usa stime informative, non dosaggio clinico e non consiglio medico. Il
modello deve essere prudente: la MED indica la dose minima che può produrre un
eritema osservabile, quindi non è un obiettivo da raggiungere.

## Fonti principali

- WHO, *Global solar UV index: a practical guide*:
  https://www.who.int/publications/i/item/9241590076
- EPA/NWS, *A Guide to the UV Index*:
  https://www.epa.gov/sites/default/files/documents/uviguide.pdf
- CIE, *Standard Erythema Dose, a Review*: 1 SED = 100 J/m²:
  https://cie.co.at/publications/standard-erythema-dose-review
- ICNIRP, *Health issues of ultraviolet tanning appliances used for cosmetic
  purposes*: fototipi, SED/MED e rischi UV:
  https://www.icnirp.org/cms/upload/publications/ICNIRPsunbed.pdf
- FDA, SPF e uso corretto della protezione solare:
  https://www.fda.gov/about-fda/center-drug-evaluation-and-research-cder/sun-protection-factor-spf
  https://www.fda.gov/drugs/understanding-over-counter-medicines/sunscreen-how-help-protect-your-skin-sun
- DermNet, classificazione Fitzpatrick:
  https://dermnetnz.org/topics/skin-phototype
- NIH ODS, vitamina D e fattori che influenzano la sintesi cutanea:
  https://ods.od.nih.gov/factsheets/VITAMIND/HealthProfessional/
- Holick/Webb-Engelsen su vitamina D da UV:
  https://pubmed.ncbi.nlm.nih.gov/18290718/
  https://pubmed.ncbi.nlm.nih.gov/20398766/

## Decisioni implementate

- `SafeExposure.wattsPerUVIndexUnit = 0.025`: 1 punto UVI equivale a
  25 mW/m² di irradianza eritemale, quindi la dose al minuto è
  `UVI * 0.025 * 60` J/m².
- `Fitzpatrick.med` contiene MED di pianificazione conservative. Per il
  fototipo I è usato 150 J/m² per restare sotto il limite superiore del range
  ICNIRP (<2 SED).
- `SafeExposure.recommendedLimitFractionOfMED = 0.8`: Solea ferma il limite
  prudente prima della MED, per non trattare l'eritema minimo come target.
- Lo SPF attenua la dose nel modello, ma non moltiplica liberamente il tempo:
  una singola applicazione è limitata a 120 minuti e lo SPF modellato è
  cappato a 50. Questo segue le avvertenze FDA: SPF è una misura relativa di
  dose, non un permesso di restare al sole N volte più a lungo.
- `BurnRisk` mappa UV 0-2 a basso, UV 3-7 a moderato e UV 8+ ad alto,
  con promozione ad alto anche quando la dose giornaliera raggiunge l'80%
  della MED di pianificazione.
- `GoldenHours` esclude UV > 7 e richiede che il limite prudente a pelle non
  protetta sia almeno 25 minuti. Sono finestre più prudenti, non "sicure".
- `VitaminD` è una stima euristica: parte da 15.000 IU per una MED a corpo
  intero, scala per superficie esposta e fototipo, e satura a 20.000 IU. Non
  può sostituire 25(OH)D sierica o indicazioni cliniche.
- `SunExposureAdvisor` trasforma il limite prudente in un piano consigliato:
  sceglie automaticamente tra vitamina D, tan graduale e prudenza usando
  fototipo, UV attuale, dose già accumulata oggi e condizione pelle. Vitamina D
  punta a ~800 IU ma non oltre il 35% della MED, tan graduale usa il 55% della
  MED, massima prudenza il 30%. Ogni consiglio sottrae la dose già accumulata
  oggi e resta sotto il limite prudente dell'80% MED.
- La condizione pelle modula il piano: pelle calda riduce la dose verso la
  prudenza; pelle che tira o arrossata blocca il sole diretto e produce un piano
  "ombra/recupero" da 0 minuti.

## Limiti noti

- Il quiz Fitzpatrick resta soggettivo e non misura la MED individuale.
- WeatherKit fornisce UVI ambientale, non esposizione personale: ombra,
  riflessi, sabbia/acqua/neve, vetri, altitudine locale, nuvole rotte,
  indumenti e postura possono cambiare la dose reale.
- L'app non conosce quantità di crema applicata, uniformità, sudore, bagno o
  asciugatura: dopo 120 minuti richiede riapplicazione esplicita.
- L'abbronzatura non è priva di rischio: UV e tanning aumentano comunque la
  dose cumulativa e il rischio cutaneo/oculare.
