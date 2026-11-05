#!/bin/sh
# Runs every check a change must pass. Usage: scripts/check.sh
set -eu
cd "$(dirname "$0")/.."

fail=0
guard() {
  if matches=$(grep -rnE "$2" lib/features); then
    echo "Rule broken: $1"
    echo "$matches"
    fail=1
  fi
}
guard 'use D or Palette instead of a color literal' 'Color\(($|[[:space:]]*0x)'
guard 'change state through a named AppState method' '\.commit\(\)'
# Only lib/app and main.dart wire implementations; inner layers see interfaces.
if matches=$(grep -rnE "^import '[^']*data/" lib/core lib/domain lib/state lib/widgets); then
  echo "Rule broken: only lib/app and main.dart may import lib/data"
  echo "$matches"
  fail=1
fi
[ "$fail" -eq 0 ]
dart run tool/feature_cycles.dart

dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
