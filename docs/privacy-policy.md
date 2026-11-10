# Kiko — Privacy Policy

Last updated: 2026-11-10

## Overview

Kiko is a call CRM (Customer Relationship Management) app for the Ethiopian
market. It helps you track leads, identify callers, manage call follow-ups,
and back up your data securely.

This privacy policy explains what data Kiko collects, how it is stored, and
how you can control it.

## Data we collect

### Lead data

You manually enter lead information into Kiko, including names, phone
numbers, business types, notes, and sections. This data is stored in a
locally encrypted SQLite database on your device.

### Call data

Kiko reads your device's call log to link calls to your leads. This
includes phone numbers, call direction (incoming/outgoing), call duration,
and timestamps. This data is stored in the local encrypted database.

### Call recordings

**Kiko does not record calls.** Kiko can link to call recordings made by
your phone's built-in call recorder. You must select the folder where your
phone stores recordings. Kiko does not upload, copy, or transmit audio
files. Only the file path and metadata (filename, duration estimate) are
stored in the local database.

**Recording consent notice:** You are responsible for complying with local
laws regarding call recording consent. In Ethiopia, recording a call
without the other party's knowledge may be illegal. Always inform the other
party before recording. Kiko only links to recordings you have already made
with your phone's built-in recorder — it does not initiate or control
recording.

### Device identifier

Kiko generates a random unique device ID stored in Android Keystore. This
is used only to identify which devices are registered to your account for
backup purposes.

### Account data

If you create a Kiko account, your email address and a password are stored
with Firebase Authentication. Your email is used for account verification
and password reset. Kiko does not send marketing emails.

## Data we do NOT collect

- **No analytics:** Kiko does not include any analytics SDKs. We do not
  track your usage, screen views, button taps, or crash reports.
- **No advertising:** Kiko does not show ads or include any advertising
  SDKs.
- **No third-party tracking:** Kiko does not share data with any
  third-party service for tracking, profiling, or advertising.
- **No location data:** Kiko does not access your GPS or location.
- **No contacts:** Kiko does not read your contacts (unless required for
  call screening on certain Android versions, in which case only the
  incoming number is matched against your local lead database).

## Data storage and encryption

### Local storage

All lead data, call history, and reminders are stored in a SQLite database
encrypted with SQLCipher. The encryption key is randomly generated and
stored in the Android Keystore. The key is independent of your PIN — even
if your PIN is removed, the database remains encrypted.

### Cloud backup

If you enable cloud backup, your data is encrypted end-to-end before
leaving your device:

1. A random 256-bit data key is generated and stored in Android Keystore.
2. Your data is serialised to JSON, compressed with GZip, and encrypted
   with AES-256-GCM using the data key.
3. The encrypted blob is uploaded to Firebase Storage.
4. A copy of the data key is wrapped (encrypted) with your recovery code
   using scrypt key derivation and stored in Firestore.
5. The data key never leaves your device unencrypted.

Only someone with your recovery code can decrypt your backup. Kiko's
servers cannot read your data.

### What is included in backups

- Lead data (name, phones, notes, sections, status)
- Call events (number, direction, duration, timestamp)
- Pending reminders

### What is NOT included in backups

- Call recording audio files or links
- Images (planned for future, currently local only)
- Device-specific settings (language, calendar mode)

## Data sharing

Kiko does not share your data with any third party. Your data is stored
locally and, if you enable cloud backup, only in your own Firebase project
(encrypted).

## Data deletion

### Delete account

You can delete your Kiko account from Settings → Cloud → Delete account.
This permanently:
- Deletes all cloud backups from Firebase Storage
- Deletes your device registry from Firestore
- Deletes your encrypted key from Firestore
- Deletes your Firebase Authentication account
- Wipes all local data on the current device

This action cannot be undone.

### Clear local data

If you want to keep your cloud backup but wipe the current device, sign out
from Settings → Cloud. Your local database and settings will be cleared, but
your cloud backup remains accessible from other registered devices.

## Data security

- Local database: SQLCipher AES-256 encryption
- Cloud backup: End-to-end AES-256-GCM encryption
- Key wrapping: scrypt (N=16384, r=8, p=1) + AES-256-GCM
- Key storage: Android Keystore (hardware-backed on supported devices)
- Transport: Firebase uses TLS for all data in transit

## Children's privacy

Kiko is a business tool and is not directed at children. We do not
knowingly collect data from children under 13. If you believe a child has
provided information to Kiko, contact us and we will delete it.

## Your rights

You have the right to:
- Access your data (export from Settings → Data → Export leads)
- Delete your data (Settings → Cloud → Delete account)
- Export your data (CSV or XLSX format, Settings → Data → Export leads)

## Changes to this policy

We will update this privacy policy as needed. We will notify users of
significant changes via the app or website.

## Contact

For privacy questions or concerns, contact:
- Email: privacy@kiko.app

## Open source

Kiko's source code is available for review. If you want to verify any
claim in this privacy policy, you can inspect the code that handles data
collection, storage, and transmission.
