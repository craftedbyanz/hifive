---
name: install-iphone
description: Install the current hifive build on the user's physical iPhone over USB or Wi-Fi without erasing its data. Use when the user asks to put, install or test the app on their iPhone or phone.
---

# Install on the iPhone

```sh
scripts/install_iphone.sh            # Release build with sync, then install
scripts/install_iphone.sh --skip-build   # reinstall the last build
```

- Never use `flutter install` or `flutter run --release` to replace the app: `flutter install` uninstalls first and erases the learner's local data. The script installs over the app with `devicectl`.
- The phone must be unlocked. Over Wi-Fi it must be paired with this Mac (by USB once before) and on the same network. Check with `xcrun devicectl list devices` instead of assuming it is connected.
- The script passes `HIFIVE_API`, so this build syncs; plain `flutter run` stays offline.
- After installing, tell the user exactly what to try on the phone for the change, especially notifications, keyboard, gestures and anything native, which widget tests and the Simulator can't prove.
