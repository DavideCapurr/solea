Tracking:

- Tracking: No.
- Third-party advertising: No.
- Data broker or cross-app tracking: No.

Data types in the current build:

- Location: used for App Functionality to retrieve weather and UV data and calculate recommended exposure limits. Not used for tracking.
- Health & Fitness: used for App Functionality. Solea can optionally write Time in Daylight to Apple Health; it does not read HealthKit data. Vitamin D remains an in-app estimate and is not written to HealthKit.
- Photos or Videos: photos selected by the user for the local diary. They are not uploaded to a Solea server.
- Gameplay Content / Game Center: leaderboards and achievements managed through Game Center when the user is signed in.

Do not declare for the current build:

- Contact Info: not collected by the app.
- Identifiers collected by Solea: no, while `CoachConfiguration.proxyURL = nil`.
- Usage Data or Diagnostics collected by Solea: no.
- Sensitive Info collected by Solea: no.
