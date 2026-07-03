#!/bin/zsh
# Build Respiro.app, zip for distribution, checksum, copy to sevenweb-portal.
set -e
cd "$(dirname "$0")"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
ZIP_NAME="Respiro-${VERSION}-macOS-arm64.zip"
DIST="dist"
PORTAL="${SEVENWEB_PORTAL:-$(dirname "$0")/sevenweb-portal/public/downloads/respiro}"

./build-app.sh

mkdir -p "$DIST"
ditto -c -k --keepParent "build/Respiro.app" "$DIST/$ZIP_NAME"
( cd "$DIST" && shasum -a 256 "$ZIP_NAME" | tee SHA256SUMS.txt )

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
