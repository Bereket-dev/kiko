# Kiko — Play Store Permissions Declaration & APK Fallback

## Overview

Kiko is a call CRM (Customer Relationship Management) app for the Ethiopian
market. It identifies incoming callers against a local lead database, shows
caller information as an overlay during calls, links call history to leads,
and provides reminders and call planning features.

This document covers the Play Store permissions declaration for the
restricted permissions Kiko uses, and the fallback distribution strategy if
Play rejects the declaration.

---

## Restricted permissions used

### READ_CALL_LOG

**Permission:** `android.permission.READ_CALL_LOG`

**Why Kiko needs it:**
Kiko reads the system call log to link incoming and outgoing calls to lead
records. After a call ends, Kiko reads the most recent call log entry to
determine call duration and direction, then associates it with the
matching lead in the local database. The Recent Calls screen also uses the
call log to show which numbers are not yet saved as leads.

**Data flow:**
- Call log entries are read on-demand (after a call ends, or when the user
  opens the Recent Calls screen).
- Call metadata (number, direction, duration, timestamp) is stored in the
  local encrypted SQLite database.
- Call log data is never sent to any server. It stays on-device in an
  SQLCipher-encrypted database.
- Call log data may be included in end-to-end encrypted cloud backups, but
  the backup is encrypted on-device before upload and the encryption key
  never leaves the device.

**Declaration text for Play Console:**
> Kiko uses READ_CALL_LOG to associate incoming and outgoing phone calls
> with customer lead records in the user's local CRM database. After each
> call, Kiko reads the call log entry to capture call duration and
> direction, linking it to the corresponding lead. This data is stored
> locally in an encrypted database and is never transmitted to any server
> in plaintext. Call log data may be included in end-to-end encrypted
> cloud backups that only the user can decrypt. Kiko does not upload,
> share, or sell call log data with any third party.

### READ_PHONE_STATE

**Permission:** `android.permission.READ_PHONE_STATE`

**Why Kiko needs it:**
Kiko uses phone state to detect when a call starts and ends, so it can
trigger the post-call status update dialog at the right moment.

**Declaration text for Play Console:**
> Kiko uses READ_PHONE_STATE to detect call start and end events. This
> allows the app to show a post-call dialog prompting the user to update
> the lead's status after a call completes. Phone state data is used only
> to time the dialog appearance and is not stored or transmitted.

### Call Screening Service

**Permission:** `android.permission.BIND_SCREENING_SERVICE` (system-level,
not a runtime permission)

**Why Kiko needs it:**
Kiko implements `CallScreeningService` to identify incoming callers
against the local lead database before the call is answered. The service
receives the incoming phone number, looks it up in the encrypted on-device
index, and shows an overlay with the caller's name and lead status.

**Declaration text for Play Console:**
> Kiko implements CallScreeningService (android.telecom.CallScreeningService)
> to identify incoming callers against the user's local CRM lead database.
> When a call arrives, Kiko looks up the caller's phone number in an
> encrypted on-device index and displays the caller's name and lead status
> as an overlay. Kiko does not block, reroute, or modify calls — it only
> displays information. The screening service does not access the internet
> during call screening; all lookups are performed against a local encrypted
> store.

### SYSTEM_ALERT_WINDOW

**Permission:** `android.permission.SYSTEM_ALERT_WINDOW`

**Why Kiko needs it:**
Kiko uses a system overlay window to display caller information (name,
status, last note, last call date) on top of the incoming call screen.
This allows the user to see lead information without switching apps.

**Declaration text for Play Console:**
> Kiko uses SYSTEM_ALERT_WINDOW to display caller identification
> information (lead name, status, and recent notes) as a small overlay on
> top of the incoming call screen. The overlay shows only the caller's CRM
> data from the local database and does not display ads or third-party
> content. The overlay appears only during incoming calls and is dismissed
> when the call ends.

---

## Non-restricted permissions

| Permission | Purpose |
|---|---|
| `POST_NOTIFICATIONS` | Show reminders and call-plan alerts (API 33+) |
| `FOREGROUND_SERVICE` | Keep the overlay service alive during calls |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prompt user to exempt from battery kill |
| `SCHEDULE_EXACT_ALARM` | Deliver reminder alarms on time (API 31+) |
| `USE_EXACT_ALARM` | Same, for API 33+ |
| `USE_FULL_SCREEN_INTENT` | Full-screen alarm notifications (API 34+) |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule alarms after device reboot |

---

## Play Store policy risks

### Risk: READ_CALL_LOG rejection

Google Play has restricted READ_CALL_LOG to apps whose core functionality
requires it (dialer, call recorder, caller ID). A CRM that links calls to
contacts may or may not qualify depending on the reviewer.

**Mitigation:** The declaration text above clearly states that call log
access is essential for the core CRM workflow (linking calls to leads). If
rejected, we will:

1. Appeal with a video demonstration of the feature.
2. If appeal fails, distribute via APK/sideload (see below).

### Risk: Call screening service rejection

CallScreeningService is a system-level service. Google has accepted caller
ID apps that use this service. The risk is low but non-zero.

**Mitigation:** The declaration text emphasises that Kiko does not block or
modify calls, only displays information. If rejected, same APK fallback
applies.

---

## Sideload / APK fallback distribution narrative

If Google Play rejects the permissions declaration, Kiko will be
distributed via direct APK download from kiko.app (or a similar domain).

### Distribution flow

1. **Website:** Users visit kiko.app and download the latest APK directly.
2. **GitHub Releases:** The APK is also published on GitHub Releases for
   transparency and version history.
3. **Update notifications:** The app checks for updates on launch and
   notifies the user when a new version is available on the website.

### Security considerations

- APKs are signed with the same release signing key.
- SHA-256 checksums are published alongside each release.
- The website uses HTTPS.
- Users are instructed to verify the checksum if they are security-conscious.

### User instructions for sideloading

1. On the Android device, go to Settings → Security (or Settings → Apps →
   Special access → Install unknown apps).
2. Enable "Install unknown apps" for the browser or file manager.
3. Download the APK from kiko.app.
4. Open the downloaded file and tap "Install".
5. After installation, open Kiko and follow the onboarding wizard.

### Tradeoffs vs Play Store

| Aspect | Play Store | Sideload |
|---|---|---|
| Discovery | High | Low (word of mouth, website) |
| Auto-update | Yes | Manual (in-app notification) |
| Permissions review | Required (may reject) | Not required |
| Revenue share | 15-30% | 0% |
| User trust | High (Google vetting) | Medium (requires checksum) |
| Reach | Global | Global (but harder to find) |

### Hybrid strategy

Kiko will attempt Play Store distribution first. If the permissions
declaration is rejected after appeal, Kiko will switch to sideload-only
distribution while maintaining a Play Store listing with a reduced feature
set (no call screening, no call log access) if feasible.

---

## Pre-submission checklist

- [ ] Test the app on at least one device per manufacturer (Samsung, Xiaomi,
  Tecno, Infinix)
- [ ] Record a demonstration video showing each restricted permission in use
- [ ] Prepare the permissions declaration text for each restricted permission
- [ ] Set up kiko.app domain (or fallback) with APK download page
- [ ] Generate release APK with production signing key
- [ ] Compute SHA-256 checksum of the APK
- [ ] Create GitHub Release with APK and checksum
