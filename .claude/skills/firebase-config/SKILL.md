---
name: firebase-config
description: Regenerate hifive's Firebase config (flutterfire configure) or register Android signing keys for project hifive-3371b. Use when adding a Firebase app or sign-in provider, when the Firebase config files are missing or stale, or when an Android signing key changes.
---

# Firebase config

Project `hifive-3371b` (Spark plan). These files are generated, never edited by hand:

- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

Regenerate them after adding an app or a sign-in provider:

```sh
flutterfire configure --project=hifive-3371b --platforms=ios,android
```

It needs the `xcodeproj` Ruby gem, installed with `gem install --user-install xcodeproj`.

Register a new Android signing key, or Google sign-in fails on that build:

```sh
firebase apps:android:sha:create <android-app-id> <sha1-or-sha256>
```

Then run `scripts/check.sh` and build both platforms. Report which files changed.
