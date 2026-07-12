Nutrition labels alignées avec `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` vide, `NSPrivacyTracking = false`).

# Tracking

- Tracking : **Non**.
- Publicité tierce : Non.
- Data broker / suivi inter-applications : Non.
- Domaines de tracking (`NSPrivacyTrackingDomains`) : aucun.

# Collecte de données

Pour la build actuelle : **Data Not Collected**.

Toutes les données que l'app lit ou écrit restent sur l'appareil de l'utilisateur
ou sont gérées par des services Apple (WeatherKit, HealthKit, Game Center).
Abbronzo ne transmet aucune donnée personnelle à ses propres serveurs ou à des
tiers.

Détail par catégorie qu'App Store Connect pourrait faire apparaître :

- **Location** : utilisée dans l'app uniquement pour appeler WeatherKit d'Apple
  (indice UV et météo). Apple gère la requête comme service système ; Abbronzo
  n'enregistre ni ne transmet la position ailleurs.
  → *Non collectée par Abbronzo.*
- **Health & Fitness** : Abbronzo **écrit** Time in Daylight dans le HealthKit
  de l'utilisateur lorsque celui-ci l'autorise. Aucune lecture HealthKit.
  Les valeurs restent dans le Health store de l'utilisateur.
  → *Non collectée par Abbronzo.*
- **Photos** : le journal photo enregistre les images choisies par l'utilisateur
  dans le SwiftData local (sandbox de l'app). Aucun upload vers Abbronzo ou tiers.
  → *Non collectée par Abbronzo.*
- **Game Center** : classements et succès sont gérés par Apple via GameKit ;
  les données Game Center sont couvertes par la politique de confidentialité
  d'Apple, pas celle de Abbronzo. → *Non collectée par Abbronzo.*
- **Identifiers** : un UUID anonyme de l'appareil (stocké dans UserDefaults,
  motifs `CA92.1` / `1C8F.1` dans le manifeste) sert uniquement au rate-limit
  côté proxy du coach **si** le proxy est configuré. Dans la build distribuée
  `SOLEA_COACH_PROXY_URL` est vide → aucun identifiant ne quitte l'appareil.

# Critical Alerts

Déclarées dans `critical_alerts.md` : utilisées uniquement pour les stop-alerts
UV pendant une séance (son qui contourne le mode Silencieux). Aucun upload de
données associé.

# Si le proxy du coach est activé à l'avenir

Si une future version définit `SOLEA_COACH_PROXY_URL` (par ex. Abbronzo Plus avec
réponses côté serveur), mettre à jour nutrition labels et manifeste en ajoutant :

- *Identifiers → Device ID* (linked / non-tracking, objectif App Functionality).
- *User Content → Other User Content* (texte des messages au coach, linked /
  non-tracking, objectif App Functionality).
- Les entrées `NSPrivacyCollectedDataTypes` correspondantes dans
  `App/PrivacyInfo.xcprivacy`.
