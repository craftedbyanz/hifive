# hifive

A Flutter (iOS + Android) language-learning app. English is the first course; more languages will follow. Everything runs locally for now.

```sh
flutter pub get
scripts/check.sh            # guards, format, analyze, test
flutter run                 # Simulator or emulator
scripts/install_iphone.sh   # Release build installed over the app on a USB iPhone, keeping its data
```

See `CLAUDE.md` for architecture and conventions, and `docs/design-system.md` for the design rules.
