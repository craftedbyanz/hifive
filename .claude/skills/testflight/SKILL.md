---
name: testflight
description: Upload a new hifive iOS build to TestFlight / App Store Connect - bump the build number, run the checks, archive with sync on, upload with xcodebuild, push. Use when the user asks to push, upload, ship or release a build to TestFlight or App Store Connect.
---

# Upload a build to TestFlight

The user asking for the upload is the go-ahead; don't ask again. Work on `main`.

## 1. Preconditions

- `git status` is clean apart from work meant for this build, and `git fetch` shows `main` is not behind `origin/main` (rebase if it is, never merge).
- Xcode is signed in to an account in team `7GH7MJS7R2`. The iOS bundle ID is `com.anznguyen.hifive.release`, not the Android `com.anznguyen.hifive`.

## 2. Build number

`pubspec.yaml` holds `version: 1.0.0+N`. If a `build(ios): prepare build N for TestFlight` commit already exists, build N was uploaded: set `N+1`. App Store Connect refuses a build number it has seen.

## 3. Check and commit

```sh
scripts/check.sh
git add pubspec.yaml && git commit -m "build(ios): prepare build <N> for TestFlight"
```

Don't go on with a red check. Keep the bump in its own commit.

## 4. Archive

```sh
flutter build ipa --release --target lib/main.dart \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=HIFIVE_API=https://hifive-api.hifive-worker.workers.dev
```

Without `HIFIVE_API` the build never syncs. Confirm the archive:

```sh
/usr/libexec/PlistBuddy -c Print build/ios/archive/Runner.xcarchive/Info.plist | grep -E 'CFBundleVersion|CFBundleIdentifier'
```

`ios/ExportOptions.plist` names the App Store profile of the app and of the `FocusActivity` widget; Flutter's own generated options name only the app, and their export fails on the widget. Flutter's export step writes `build/ios/ipa/hifive.ipa` but does not upload.

## 5. Upload

Copy the export options to a temporary file (the job's `tmp` folder when running as a job), set the destination to `upload`, and export with provisioning updates, which lets xcodebuild use the Xcode account (no API key needed):

```sh
cp ios/ExportOptions.plist "$TMP/ExportUpload.plist"
/usr/libexec/PlistBuddy -c "Set :destination upload" "$TMP/ExportUpload.plist" \
  || /usr/libexec/PlistBuddy -c "Add :destination string upload" "$TMP/ExportUpload.plist"
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$TMP/ExportUpload.plist" -exportPath "$TMP/upload" \
  -allowProvisioningUpdates
```

Success prints `Upload succeeded` and `** EXPORT SUCCEEDED **`.

## 6. Push and report

`git push origin main`, then tell the user:

- the build number, and that Apple processes it for about 5 to 15 minutes before it shows in TestFlight;
- a short English "What to Test" note for Beta App Review (one line on what changed, one on what to try);
- that App Review needs the email demo account under Test Information, since the app requires sign-in;
- what wasn't verified on a real iPhone.

## Known problems

- **Signing fails for `FocusActivity` or the App Group:** Xcode needs both App Store profiles, "HiFive AppStore Distribution" (with the App Group) and "Hi Five Distribution Profile" (the extension), and no stale copy of the same name (`docs/garden-plan.md`, step 10). Only the account holder can regenerate them; ask the user for fresh downloads.
- **Family Controls** is only in the Debug and Profile entitlements until Apple approves distribution; Release must not carry it.
- **"Redundant binary upload":** the build number was already used. Bump it again.
