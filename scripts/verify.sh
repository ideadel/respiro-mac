#!/bin/zsh
# Build and run all CLI self-tests (no Xcode required).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▸ swift build -c release"
swift build -c release
BIN=".build/release/Respiro"

echo "▸ fixture disinstallatore"
./scripts/make-fixture.sh create

echo "▸ --selftest-uninstaller"
"$BIN" --selftest-uninstaller

echo "▸ --selftest-denylist"
"$BIN" --selftest-denylist

echo "▸ --selftest-cleanup"
"$BIN" --selftest-cleanup

echo "▸ --selftest-appscanner"
"$BIN" --selftest-appscanner

echo "▸ --selftest-systemextension"
"$BIN" --selftest-systemextension

echo "✅ verify OK"
