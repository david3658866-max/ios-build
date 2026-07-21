# iOS Third-Party Signing Build Guide

## Goal

- Build an iOS IPA on Codemagic macOS.
- Hand the IPA to a third-party Apple signing provider.
- Do not use TestFlight, App Store Connect, or APNs push for this phase.
- Do not require in-place upgrades for this phase.

## Current App Info

- Display name: Xingyu
- Bundle ID: `com.cyberis.vortek`
- Version: read from `pubspec.yaml`, same as Android.
- Build environment: production, `--dart-define=APP_ENV=prod`.
- Codemagic workflow: `ios-third-party-signing`
- IPA artifact: `build/ios/Runner-unsigned-prod.ipa`

## Required From Owner

1. A Codemagic account with access to this Flutter repository.
2. A third-party signing provider that accepts IPA files.
3. At least one iPhone for real-device testing.
4. A source brand logo if the icon needs to be regenerated.

Icon note: `pubspec.yaml` already configures `flutter_launcher_icons`, and the current workspace has `assets/image/app_icon.png` plus the default source `logo.jpg`. To regenerate matching Android and iOS icons, run:

```bash
node tool/sync-brand-icons.js
flutter pub run flutter_launcher_icons
```

## Codemagic Build

Run the `ios-third-party-signing` workflow in Codemagic. It will:

1. Run `flutter pub get`.
2. Run `flutter build ios --release --no-codesign --dart-define=APP_ENV=prod`.
3. Package `Runner.app` into an unsigned IPA.
4. Export `Runner-unsigned-prod.ipa`.

## Signing Provider Handoff

Send `Runner-unsigned-prod.ipa` to the provider and ask them to:

- Keep Bundle ID as `com.cyberis.vortek` if possible.
- No APNs capability is required.
- No App Store upload is required.
- No TestFlight upload is required.
- No in-place upgrade support is required for the first test.
- Do not remove `Info.plist` permission descriptions.
- Re-sign the main app and embedded frameworks completely.

If the provider cannot keep the Bundle ID, it is acceptable for the first install test, but they should keep the replacement Bundle ID stable across builds.

## Real Device Acceptance Checklist

- App installs and opens.
- Display name is Xingyu.
- Login works against production.
- Conversation list loads.
- WebSocket send and receive works.
- Text message sending works.
- Camera and photo picker work.
- QR scanning works.
- Contacts permission prompt and access work.
- File picking, preview, or download works.

## Risks

- Third-party signing can be revoked by Apple.
- Changing Bundle ID makes permissions, login state, and local data behave like a new app.
- Incomplete re-signing can cause startup crashes or permission failures.
