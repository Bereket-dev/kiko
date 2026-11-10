# Kiko — OEM Device Compatibility Matrix

Tested Android versions: 10 (API 29) through 14 (API 34).
Target manufacturers: Samsung, Xiaomi, Tecno, Infinix (Transsion).

## Summary

| Feature | Samsung | Xiaomi | Tecno | Infinix |
|---|---|---|---|---|
| Call screening | ✅ | ✅ | ✅ | ✅ |
| Overlay window | ✅ | ✅ | ✅ | ✅ |
| Alarms (setAlarmClock) | ✅ | ⚠️ See notes | ⚠️ See notes | ⚠️ See notes |
| OEM call recorder | Voice Recorder | MIUI Dialer | HiOS Dialer | XOS Dialer |
| Battery kill risk | Medium | High | High | High |
| Autostart whitelist | Not required | Required | Required | Required |

Legend: ✅ Works out of box · ⚠️ Requires user action

---

## Android version notes

### Android 10 (API 29)

- CallScreeningService works reliably across all manufacturers.
- POST_NOTIFICATIONS not required (added in API 33).
- PROCESS_OUTGOING_CALLS still available (maxSdk 28 in manifest, no-op on 10+).

### Android 11 (API 30)

- No changes affecting Kiko's feature set.

### Android 12 (API 31)

- SCHEDULE_EXACT_ALARM introduced. Kiko uses `setAlarmClock()` which does
  not require this permission, but it is declared as a belt-and-suspenders
  measure.
- Foreground service launch restrictions from the background begin. Kiko's
  overlay is started by the Telecom framework, not the app, so this does not
  affect us.

### Android 13 (API 33)

- POST_NOTIFICATIONS runtime permission required. Handled in the
  permissions wizard.
- USE_EXACT_ALARM available for clock/calendar category apps. Declared in
  manifest.

### Android 14 (API 34)

- USE_FULL_SCREEN_INTENT required for fullscreen alarm notifications.
  Declared in manifest. If the user denies, Kiko falls back to a
  high-priority heads-up notification (handled in NotificationHelper.kt).
- Foreground service types required. Kiko's overlay runs as a bound
  service from Telecom, not a foreground service, so no type declaration
  is needed.

---

## Manufacturer-specific details

### Samsung (One UI)

#### Call screening
Works reliably on Android 10+. The Telecom framework binds to
`KikoCallScreeningService` as expected.

#### Overlay
Standard `SYSTEM_ALERT_WINDOW` permission. No special handling needed.

#### Alarms
`setAlarmClock()` works reliably. Samsung does not aggressively kill
alarm-related apps. Boot receiver fires after restart.

#### OEM call recorder
Samsung's Voice Recorder app does not auto-record calls by default. Users
who want call recording must enable it in the Samsung Phone app settings
(available on certain region firmware). Kiko's recording match engine
handles files placed in any user-selected SAF folder.

#### Battery optimisation
- **Risk:** Medium. Samsung's battery management is less aggressive than
  Xiaomi or Transsion, but still kills background services after extended
  inactivity.
- **Settings path:** Settings → Apps → Kiko → Battery → Unrestricted
- **Instructions for users:**
  1. Open Settings → Apps
  2. Find and tap Kiko
  3. Tap Battery
  4. Select "Unrestricted"

---

### Xiaomi (MIUI / HyperOS)

#### Call screening
Works on Android 10+. MIUI's built-in call screening may prompt the user
to choose between MIUI's screening and Kiko's. The user must select Kiko.

#### Overlay
Standard permission. MIUI may show an additional warning about "displaying
over other apps" — this is cosmetic and can be dismissed.

#### Alarms
**Requires autostart whitelist.** Xiaomi aggressively kills background
apps. Without autostart permission, alarms will not fire after a force-stop
or device reboot.

- **Autostart path:** Settings → Apps → Permissions → Autostart → Enable
  Kiko
- **Battery path:** Settings → Apps → Kiko → Battery saver → No
  restrictions

#### OEM call recorder
MIUI Dialer includes call recording on some region firmware. Files are
typically stored in `/MIUI/sound_recorder/call_recorder/` or similar. Users
select this folder via SAF in Kiko's recording settings.

#### Battery optimisation
- **Risk:** High. MIUI is one of the most aggressive battery killers.
- **Settings path:** Settings → Apps → Kiko → Battery saver → No
  restrictions
- **Additional:** Settings → Apps → Permissions → Autostart → Enable Kiko
- **Instructions for users:**
  1. Open Settings → Apps → Permissions → Autostart
  2. Find Kiko and enable the toggle
  3. Go back to Settings → Apps → Kiko
  4. Tap "Battery saver"
  5. Select "No restrictions"

---

### Tecno (HiOS)

#### Call screening
Works on Android 10+. HiOS supports the Telecom framework.

#### Overlay
Standard permission. HiOS may require an additional "Display popup windows
while running in background" permission in Security settings.

#### Alarms
**Requires autostart whitelist.** HiOS kills background apps aggressively.
- **Autostart path:** Phone Manager → Autostart Manager → Enable Kiko
- **Battery path:** Settings → Battery → Kiko → Disable battery
  optimisation

#### OEM call recorder
HiOS Dialer includes call recording on some models. Files are typically
stored in the internal storage under a HiOS-specific folder. Users select
this folder via SAF.

#### Battery optimisation
- **Risk:** High. Transsion devices (Tecno/Infinix) are aggressive battery
  killers.
- **Settings path:** Settings → Battery → Kiko → Don't optimise
- **Additional:** Phone Manager → Autostart Manager → Enable Kiko
- **Instructions for users:**
  1. Open Phone Manager (or HiOS Security)
  2. Tap Autostart Manager
  3. Find Kiko and enable it
  4. Open Settings → Battery
  5. Find Kiko and select "Don't optimise" (or "Unrestricted")

---

### Infinix (XOS)

#### Call screening
Works on Android 10+. XOS supports the Telecom framework.

#### Overlay
Same as Tecno — may require "Display popup windows while running in
background" in XOS Security settings.

#### Alarms
**Requires autostart whitelist.** XOS kills background apps aggressively.
- **Autostart path:** XOS Security → Autostart Management → Enable Kiko
- **Battery path:** Settings → Battery → Kiko → Disable battery
  optimisation

#### OEM call recorder
XOS Dialer includes call recording on some models. Files stored in
XOS-specific folders. Users select via SAF.

#### Battery optimisation
- **Risk:** High. Same as Tecno (both are Transsion brands).
- **Settings path:** Settings → Battery → Kiko → Don't optimise
- **Additional:** XOS Security → Autostart Management → Enable Kiko
- **Instructions for users:**
  1. Open XOS Security
  2. Tap Autostart Management
  3. Find Kiko and enable it
  4. Open Settings → Battery
  5. Find Kiko and select "Don't optimise" (or "Unrestricted")

---

## General fallback

For manufacturers not listed above (Pixel, Motorola, OnePlus, etc.):

1. Settings → Apps → Kiko → Battery → Unrestricted / Don't optimise
2. If the device has an autostart manager, enable Kiko there
3. If alarms are unreliable, check Settings → Apps → Kiko → Alarms (Android
   12+)

---

## Testing checklist

For each manufacturer + Android version:

- [ ] Call screening fires for incoming calls (app closed)
- [ ] Overlay shows lead name and status during call
- [ ] Post-call dialog appears after call ends (app closed)
- [ ] Alarm fires at scheduled time after device reboot
- [ ] Alarm fires after force-stop (if autostart is enabled)
- [ ] Call recording files detected in user-selected folder
- [ ] Background backup (WorkManager) runs on schedule
