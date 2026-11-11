#!/bin/bash
# Builds the Release app and installs it over the current one on an iPhone,
# keeping the app's data. Installs fresh if the app is not on the phone.
# Uses iPhones connected by USB; with none, a paired iPhone on the same Wi-Fi
# (unlocked, and paired with this Mac by USB once before). Picks the iPhone
# automatically, or asks when there are several.
# Usage: scripts/install_iphone.sh [--skip-build]
#
# Uses devicectl because `flutter install` uninstalls the old version first,
# which would erase the local data on the phone.
set -eu
cd "$(dirname "$0")/.."

app=build/ios/iphoneos/Runner.app
skip_build=0
case "${1:-}" in
  '') ;;
  --skip-build) skip_build=1 ;;
  *) echo "Usage: scripts/install_iphone.sh [--skip-build]" >&2; exit 2 ;;
esac

json=$(mktemp)
trap 'rm -f "$json"' EXIT
xcrun devicectl list devices --quiet --json-output "$json" >/dev/null

udids=()
labels=()
while IFS=$'\t' read -r udid label; do
  udids+=("$udid")
  labels+=("$label")
done < <(python3 -I - "$json" <<'PY'
import json, sys
wired, wifi = [], []
for d in json.load(open(sys.argv[1]))["result"]["devices"]:
    hw, props, conn = d["hardwareProperties"], d["deviceProperties"], d["connectionProperties"]
    if hw.get("deviceType") != "iPhone" or hw.get("reality") != "physical":
        continue
    label = f'{props["name"]} ({hw.get("marketingName") or hw.get("productType")}, {hw["udid"]}'
    if conn.get("transportType") == "wired":
        wired.append(f'{hw["udid"]}\t{label})')
    elif conn.get("transportType") == "localNetwork" and conn.get("pairingState") == "paired":
        wifi.append(f'{hw["udid"]}\t{label}, Wi-Fi)')
for line in wired or wifi:
    print(line)
PY
)

count=${#udids[@]}
if [ "$count" -eq 0 ]; then
  echo "No iPhone found by USB or Wi-Fi. Plug it in, unlock it and trust this Mac." >&2
  exit 1
elif [ "$count" -eq 1 ]; then
  target=${udids[0]}
  echo "iPhone: ${labels[0]}"
else
  echo "Several iPhones are connected:"
  target=
  PS3="Choose an iPhone (1-$count): "
  select label in "${labels[@]}"; do
    if [ -n "$label" ]; then
      target=${udids[$((REPLY - 1))]}
      break
    fi
    echo "Enter a number from 1 to $count."
  done
  if [ -z "$target" ]; then
    echo "No iPhone chosen." >&2
    exit 1
  fi
fi

if [ "$skip_build" -eq 0 ]; then
  # The sync Worker; set HIFIVE_API to build against another one, or to an
  # empty string for an offline-only build.
  flutter build ios --release --target lib/main.dart \
    --dart-define=HIFIVE_API="${HIFIVE_API-https://hifive-api.hifive-worker.workers.dev}"
fi
if [ ! -d "$app" ]; then
  echo "$app not found. Run without --skip-build." >&2
  exit 1
fi

xcrun devicectl device install app --device "$target" "$app"
echo "Installed on $target."
