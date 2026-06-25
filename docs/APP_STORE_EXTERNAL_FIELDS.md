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

Gli stessi URL devono essere copiati in `project.yml` nelle chiavi
`SoleaPrivacyPolicyURL` e `SoleaSupportURL`, così l'app mostra i link nel
Profilo.

Bozze pubblicabili:

- Privacy Policy: `docs/PRIVACY_POLICY_DRAFT.md`
- Support page: `docs/SUPPORT_PAGE_DRAFT.md`

Export HTML statico:

```sh
scripts/export-public-pages.sh --contact-email <email> --privacy-url <privacy-url> --support-url <support-url>
```

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
