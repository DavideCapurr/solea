Nutrition labels aligned with `App/PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` empty, `NSPrivacyTracking = false`).

# Tracking

- Tracking: **No**.
- Third-party advertising: No.
- Data broker / cross-app tracking: No.
- Tracking domains (`NSPrivacyTrackingDomains`): none.

# Data Collection

For the current build: **Data Not Collected**.

Every data type the app reads or writes stays on the user's device or is
handled by Apple-managed services (WeatherKit, HealthKit, Game Center). Solea
does not transmit personal data to its own servers or to third parties.

Per-category notes (in case App Store Connect surfaces them in the questionnaire):

- **Location**: used in-app only to call Apple's WeatherKit for UV index and
  weather. Apple handles the request as a system service; Solea does not log
  or transmit location anywhere else. → *Not collected by Solea.*
- **Health & Fitness**: Solea **writes** Time in Daylight to the user's
  HealthKit store when explicitly authorized. It does not read HealthKit
  data. Values stay in the user's Health store. → *Not collected by Solea.*
- **Photos**: the photo diary saves user-selected images into the local
  SwiftData store (app sandbox). No upload to Solea or third parties.
  → *Not collected by Solea.*
- **Game Center**: leaderboards and achievements are managed by Apple via
  GameKit; Game Center data is covered by Apple's privacy policy, not Solea's.
  → *Not collected by Solea.*
- **Identifiers**: an anonymous device UUID (saved in UserDefaults, reasons
  `CA92.1` / `1C8F.1` in the manifest) is only used for rate-limiting on the
  coach proxy **if** the proxy is configured. In the shipped build
  `SOLEA_COACH_PROXY_URL` is empty → no identifier ever leaves the device.

# Critical Alerts

Declared in `critical_alerts.md`: used only for UV stop-alerts during a session
(sound that bypasses Silent Mode). No data upload is associated.

# If the coach proxy is enabled in the future

If a future release sets `SOLEA_COACH_PROXY_URL` (e.g. Solea Plus with
server-side replies), update both the nutrition labels and the manifest:

- *Identifiers → Device ID* (linked / non-tracking, purpose: App Functionality).
- *User Content → Other User Content* (text of coach messages, linked /
  non-tracking, purpose: App Functionality).
- Corresponding `NSPrivacyCollectedDataTypes` entries in
  `App/PrivacyInfo.xcprivacy`.
