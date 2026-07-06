#!/bin/zsh
# Notarize Respiro.app (requires Apple Developer ID + app-specific password).
# Usage: DEVELOPER_ID="Developer ID Application: …" NOTARY_PROFILE=respiro ./scripts/notarize.sh
set -e
cd "$(dirname "$0")/.."

APP="build/Respiro.app"
ZIP="build/Respiro-notarize.zip"

if [[ -z "$DEVELOPER_ID" ]]; then
  echo "❌ Imposta DEVELOPER_ID (es. \"Developer ID Application: SevenWeb (TEAMID)\")"
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  echo "❌ Manca $APP — esegui prima ./build-app.sh con DEVELOPER_ID"
  exit 1
fi

ditto -c -k --keepParent "$APP" "$ZIP"

if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
else
  echo "❌ Imposta NOTARY_PROFILE (notarytool store-credentials) oppure usa --apple-id manualmente"
  exit 1
fi

xcrun stapler staple "$APP"
echo "✅ Notarizzazione completata: $APP"
