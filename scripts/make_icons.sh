#!/bin/bash
# Renders the iOS and Android app icons and launch images from the logo
# painter (lib/widgets/branding.dart), then removes the alpha channel from
# the iOS icons, which the App Store refuses. Run after changing the logo.
set -eu
cd "$(dirname "$0")/.."

flutter test tool/app_icons_test.dart

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
while read -r icon; do
  # A JPEG round trip at best quality drops alpha; the icons are opaque.
  sips -s format jpeg -s formatOptions best "$icon" --out "$work/icon.jpg" >/dev/null
  sips -s format png "$work/icon.jpg" --out "$icon" >/dev/null
done < <(find ios/Runner/Assets.xcassets/AppIcon.appiconset -name '*.png')
echo "Icons written."
