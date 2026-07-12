Nutrition labels alinhadas com `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` vazio, `NSPrivacyTracking = false`).

# Tracking

- Tracking: **Não**.
- Publicidade de terceiros: Não.
- Data broker / tracking entre apps: Não.
- Domínios de tracking (`NSPrivacyTrackingDomains`): nenhum.

# Recolha de dados

Para o build atual: **Data Not Collected**.

Todos os dados que a app lê ou escreve permanecem no dispositivo do utilizador
ou são geridos por serviços Apple (WeatherKit, HealthKit, Game Center). A
Abbronzo não transmite dados pessoais para servidores próprios nem para terceiros.

Detalhe por categoria que a App Store Connect pode apresentar no questionário:

- **Location**: usada na app apenas para chamar o WeatherKit da Apple (índice
  UV e meteorologia). A Apple processa o pedido como serviço de sistema; a
  Abbronzo não regista nem transmite a localização para outro lado.
  → *Não recolhida pela Abbronzo.*
- **Health & Fitness**: a Abbronzo **escreve** Time in Daylight no HealthKit do
  utilizador quando autorizado. Não lê dados do HealthKit. Os valores
  permanecem no Health store do utilizador.
  → *Não recolhida pela Abbronzo.*
- **Photos**: o diário fotográfico guarda as imagens escolhidas pelo utilizador
  no SwiftData local (sandbox da app). Sem upload para a Abbronzo nem para
  terceiros. → *Não recolhida pela Abbronzo.*
- **Game Center**: tabelas de classificação e troféus são geridos pela Apple
  via GameKit; os dados do Game Center estão cobertos pela política de
  privacidade da Apple, não pela da Abbronzo. → *Não recolhida pela Abbronzo.*
- **Identifiers**: um UUID anónimo do dispositivo (guardado em UserDefaults,
  motivos `CA92.1` / `1C8F.1` no manifest) é usado apenas para rate-limit no
  proxy do coach **se** o proxy estiver configurado. No build enviado
  `SOLEA_COACH_PROXY_URL` está vazio → nenhum identificador sai do dispositivo.

# Critical Alerts

Declarados em `critical_alerts.md`: usados apenas para os stop-alerts UV
durante uma sessão (som que ignora o modo Silencioso). Sem upload de dados
associado.

# Se o proxy do coach for ativado no futuro

Caso uma release futura defina `SOLEA_COACH_PROXY_URL` (ex.: Abbronzo Plus com
respostas server-side), atualizar nutrition labels e manifest acrescentando:

- *Identifiers → Device ID* (linked / sem tracking, propósito App Functionality).
- *User Content → Other User Content* (texto das mensagens ao coach, linked /
  sem tracking, propósito App Functionality).
- As entradas `NSPrivacyCollectedDataTypes` correspondentes em
  `App/PrivacyInfo.xcprivacy`.
