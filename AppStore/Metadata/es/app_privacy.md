Nutrition labels alineadas con `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` vacío, `NSPrivacyTracking = false`).

# Tracking

- Tracking: **No**.
- Publicidad de terceros: No.
- Data broker / tracking entre apps: No.
- Dominios de tracking (`NSPrivacyTrackingDomains`): ninguno.

# Recolección de datos

Para la build actual: **Data Not Collected**.

Todos los datos que la app lee o escribe permanecen en el dispositivo del
usuario o son gestionados por servicios de Apple (WeatherKit, HealthKit, Game
Center). Tanora no transmite datos personales a servidores propios ni a terceros.

Detalle por categoría que App Store Connect podría preguntar:

- **Location**: usada en la app solo para llamar a WeatherKit de Apple para el
  índice UV y el tiempo. Apple gestiona la solicitud como servicio del sistema;
  Tanora no registra ni transmite la ubicación a ningún otro lugar.
  → *No recolectada por Tanora.*
- **Health & Fitness**: Tanora **escribe** Time in Daylight en el HealthKit
  del usuario cuando se autoriza. No lee datos de HealthKit. Los valores
  permanecen en el Health store del usuario. → *No recolectada por Tanora.*
- **Photos**: el diario fotográfico guarda las imágenes elegidas por el usuario
  en SwiftData local (sandbox de la app). Sin upload a Tanora ni a terceros.
  → *No recolectada por Tanora.*
- **Game Center**: clasificaciones y logros los gestiona Apple vía GameKit; los
  datos de Game Center están cubiertos por la política de privacidad de Apple,
  no por la de Tanora. → *No recolectada por Tanora.*
- **Identifiers**: un UUID anónimo del dispositivo (guardado en UserDefaults,
  motivos `CA92.1` / `1C8F.1` en el manifest) se usa solo para rate-limit en el
  proxy del coach **si** el proxy está configurado. En la build distribuida
  `SOLEA_COACH_PROXY_URL` está vacío → ningún identificador sale del dispositivo.

# Critical Alerts

Declaradas en `critical_alerts.md`: usadas solo para los stop-alert UV durante
una sesión (sonido que omite el modo Silencio). Sin upload de datos asociado.

# Si en el futuro se habilita el proxy del coach

Si una release futura define `SOLEA_COACH_PROXY_URL` (p. ej. Tanora Plus con
respuestas server-side), actualizar nutrition labels y manifest añadiendo:

- *Identifiers → Device ID* (linked / no tracking, propósito App Functionality).
- *User Content → Other User Content* (texto de los mensajes al coach, linked /
  no tracking, propósito App Functionality).
- Las correspondientes entradas `NSPrivacyCollectedDataTypes` en
  `App/PrivacyInfo.xcprivacy`.
