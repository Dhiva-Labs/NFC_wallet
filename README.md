# NFC Wallet

An Android app to **store, secure and clone NFC cards, keys and tags** — by DhivaLabs.

Scan any NFC tag, give it a name, type, colour and icon, and keep it in a tidy
wallet. Copy compatible tags onto blank writable tags, and lock sensitive cards
behind your fingerprint or a PIN. Everything is stored **only on your device**.

## Features

- **Scan & store** — read a tag's serial (UID), technologies and NDEF content,
  then save it with a custom name, one of nine **types** (Card, Key/Fob, Access,
  Transit, Payment, Loyalty, ID/Badge, Business, Other), a colour and notes.
- **Clone** — copy a tag's NDEF data onto a blank, writable tag
  (e.g. NTAG213/215/216 stickers, MIFARE Ultralight).
- **Secure ("safe") a card** — mark a card as protected so its UID and data are
  masked until you authenticate with biometrics / device credential / app PIN.
- **App lock** — optionally require authentication to open the app.
- **Wallet UI** — gradient "credit-card" visuals, search, type filters, a raw-data
  inspector, and a light/dark/auto theme.

## What can and can't be cloned — read this

NFC cloning is widely misunderstood. This app is honest about the limits:

| Tag kind | Copyable? |
|---|---|
| Blank/writable NDEF tags (NTAG, MIFARE Ultralight NFC stickers) | ✅ NDEF data can be copied |
| Read-only / locked NDEF tags | ⚠️ Stored for reference only |
| Bank / EMV **payment cards** | ❌ Cryptographically impossible |
| Encrypted access fobs (MIFARE DESFire, hotel/office keycards) | ❌ Protected by design |
| A tag's **UID / serial number** | ❌ Not copied (fixed in silicon on standard tags) |

In short: the app copies **NDEF content** onto blank tags. It does **not** and
**cannot** duplicate secure, encrypted, or UID-authenticated credentials. Use it
for your own tags and legitimate purposes only.

## Tech

- Flutter (Material 3), Android only.
- [`nfc_manager`](https://pub.dev/packages/nfc_manager) — NDEF read/write + low-level tag tech.
- [`local_auth`](https://pub.dev/packages/local_auth) — biometric / device-credential.
- `provider`, `shared_preferences`, `uuid`, `crypto`.

### Project layout

```
lib/
  models/     card_type, stored_card, nfc_capture, ndef_record_data
  services/   nfc_service, storage_service, auth_service
  providers/  wallet_provider, settings_provider
  widgets/    wallet_card_view, nfc_pulse, nfc_session_sheet, editor_fields, …
  screens/    home, save_card, card_detail, edit_card, raw_data, settings, lock
  app.dart, main.dart
```

## Build & run

```bash
flutter pub get
flutter run                 # on a physical NFC-capable Android device
flutter build apk --release
```

**Requirements**

- A **physical Android phone with NFC** (emulators have no NFC radio).
- `minSdk 23` (biometrics), Android SDK platform 36 installed.

> Note: `nfc_manager 3.x` pins an old `compileSdk`. `android/build.gradle.kts`
> contains a small subprojects override that bumps library modules to
> `compileSdk 36` so the AndroidX dependencies resolve.

## Status

Compiles clean (`flutter analyze`) and builds a debug APK. NFC read/write and
biometric flows are **not yet verified on hardware** — test on a real device.

## Sponsors

Dhiva Labs is an independent, self-funded lab. [Sponsorships](https://github.com/sponsors/Dhiva-Labs) help bring this project and the rest of Dhiva Labs to every platform, iPhone and Mac included.

[![Sponsor Dhiva Labs](https://img.shields.io/badge/Sponsor-Dhiva%20Labs-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/Dhiva-Labs)

Monthly sponsors at $10 and up are listed here:

<!-- sponsors -->
*Be the first: [sponsor Dhiva Labs](https://github.com/sponsors/Dhiva-Labs).*
<!-- sponsors -->
