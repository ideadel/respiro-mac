#!/bin/zsh
# Build Respiro.app, zip for distribution, checksum, copy to sevenweb-portal.
set -e
cd "$(dirname "$0")"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
ZIP_NAME="Respiro-${VERSION}-macOS-arm64.zip"
DIST="dist"
PORTAL="${SEVENWEB_PORTAL:-$(dirname "$0")/../sevenweb-portal/public/downloads/respiro}"

./build-app.sh

mkdir -p "$DIST"
ditto -c -k --keepParent "build/Respiro.app" "$DIST/$ZIP_NAME"
( cd "$DIST" && shasum -a 256 "$ZIP_NAME" | tee SHA256SUMS.txt )

# --- Appcast Sparkle -------------------------------------------------------
# Prerequisiti una tantum (vedi Sparkle docs):
#   1. ./bin-sparkle generate_keys        → stampa la chiave PUBBLICA e salva
#      quella privata nel Portachiavi. Metti la pubblica in Resources/Info.plist
#      alla voce SUPublicEDKey (al posto del placeholder) e ricompila.
#   2. Da quel momento questo blocco firma lo zip e genera dist/appcast.xml,
#      da caricare su https://sevenweb.tv/downloads/respiro/appcast.xml
GENERATE_APPCAST=$(find .build/artifacts -type f -name "generate_appcast" 2>/dev/null | head -1)
PUBLIC_KEY=$(/usr/libexec/PlistBuddy -c "Print SUPublicEDKey" Resources/Info.plist 2>/dev/null || true)
if [[ -n "$GENERATE_APPCAST" && -n "$PUBLIC_KEY" && "$PUBLIC_KEY" != *REPLACE* ]]; then
  "$GENERATE_APPCAST" --download-url-prefix "https://sevenweb.tv/downloads/respiro/" "$DIST" \
    && echo "✅ Appcast generato: $DIST/appcast.xml" \
    || echo "⚠️  generate_appcast fallito (chiave privata nel Portachiavi?)"
else
  echo "ℹ️  Appcast saltato: genera le chiavi Sparkle e imposta SUPublicEDKey in Resources/Info.plist."
  echo "   Tool: $(find .build/artifacts -type f -name 'generate_keys' 2>/dev/null | head -1)"
fi

if [[ -d "$(dirname "$PORTAL")" ]]; then
  mkdir -p "$PORTAL"
  cp "$DIST/$ZIP_NAME" "$DIST/SHA256SUMS.txt" "$PORTAL/"
  echo "✅ Copiato in $PORTAL"
else
  echo "⚠️  Portale non trovato: $PORTAL"
  echo "   Imposta SEVENWEB_PORTAL o crea ../sevenweb-portal"
fi

echo "✅ Release: $DIST/$ZIP_NAME"
echo "   SHA256: $(shasum -a 256 "$DIST/$ZIP_NAME" | awk '{print $1}')"
