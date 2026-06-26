# App Store Connect external fields

Compila questi campi in App Store Connect prima della submission finale. Sono
esterni al codice e non possono essere verificati completamente dal preflight
locale.

Fonti Apple consultate il 17 giugno 2026:

- App Store Connect Help, "App information".
- App Store Connect Help, "Platform version information".
- App Store Connect Help, "Submit Game Center components".

Gli URL possono essere scritti come autolink Markdown (`<https://...>`) oppure
come testo semplice. Sostituisci invece tutti i placeholder descrittivi tra
parentesi angolari, come `<email>` o `<telefono>`.

## Required URLs

- Privacy Policy URL: <https://davidecapurr.github.io/solea/privacy/>
- Support URL: <https://davidecapurr.github.io/solea/support/>
- Terms of Use (EULA): EULA standard di Apple, <https://www.apple.com/legal/internet-services/itunes/dev/stdeula/>

Privacy e Support vanno copiati in `project.yml` nelle chiavi
`SoleaPrivacyPolicyURL` e `SoleaSupportURL`, così l'app mostra i link nel
Profilo. Solea usa l'**EULA standard di Apple** (linea guida 3.1.2): nessun EULA
custom da impostare in App Store Connect, basta tenere il link nella App
Description. L'app linka l'EULA standard Apple nel paywall di Solea Plus e in
Profilo (`AppStoreLinks.termsOfUseURL`).

Bozze pubblicabili:

- Privacy Policy: `docs/PRIVACY_POLICY_DRAFT.md`
- Support page: `docs/SUPPORT_PAGE_DRAFT.md`

Export HTML statico:

```sh
scripts/export-public-pages.sh --contact-email <email> --privacy-url <privacy-url> --support-url <support-url>
```

Le pagine in `AppStore/Public/` vanno pubblicate sul branch `gh-pages` come
`privacy/index.html` e `support/index.html`.

Sync URL dentro l'app:

```sh
scripts/sync-app-store-urls.sh
```

## App Review Contact

- Contact name: Davide Capurro
- Contact email: davidecapurro@icloud.com
- Contact phone: +39 3917342651

## App Information

- SKU: solea-ios
- Copyright: 2026 Davide Capurro

## Review Access

- Sign-in required: No
- Demo account: N/A

## External Portal Gates

- Critical Alerts approval: Not used
- Game Center components: created
