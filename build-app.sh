#!/bin/zsh
# Builds Respiro.app from the Swift package and signs it ad-hoc.
# No Xcode required — works with Command Line Tools alone.
set -e
cd "$(dirname "$0")"

# --- App icon: build AppIcon.icns from the 1024 master (iconutil ships with CLT) ---
ICON_SRC="Resources/AppIcon/icon_1024.png"
ICON_ICNS="build/AppIcon.icns"
if [[ -f "$ICON_SRC" ]]; then
  ICONSET="build/AppIcon.iconset"
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  for spec in "16 16x16" "32 16x16@2x" "32 32x32" "64 32x32@2x" \
              "128 128x128" "256 128x128@2x" "256 256x256" "512 256x256@2x" \
              "512 512x512" "1024 512x512@2x"; do
    px="${spec%% *}"; name="${spec##* }"
    sips -z "$px" "$px" "$ICON_SRC" --out "$ICONSET/icon_${name}.png" >/dev/null 2>&1
  done
  iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
fi

swift build -c release

APP="build/Respiro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Respiro "$APP/Contents/MacOS/Respiro"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Bundle the SwiftPM resource bundle (menu bar glyph) next to the executable.
if [[ -d ".build/release/Respiro_Respiro.bundle" ]]; then
  cp -R ".build/release/Respiro_Respiro.bundle" "$APP/Contents/Resources/"
fi

# Embed Sparkle.framework (SwiftPM binary artifact) for auto-updates.
SPARKLE_FW=$(find .build/artifacts -type d -name "Sparkle.framework" -path "*macos*" 2>/dev/null | head -1)
[[ -z "$SPARKLE_FW" ]] && SPARKLE_FW=$(find .build/artifacts -type d -name "Sparkle.framework" 2>/dev/null | head -1)
if [[ -n "$SPARKLE_FW" ]]; then
  mkdir -p "$APP/Contents/Frameworks"
  cp -R "$SPARKLE_FW" "$APP/Contents/Frameworks/"
  codesign --force -s - "$APP/Contents/Frameworks/Sparkle.framework"
else
  echo "⚠️  Sparkle.framework non trovato in .build/artifacts — l'app non potrà auto-aggiornarsi."
fi

# Install the app icon.
if [[ -f "$ICON_ICNS" ]]; then
  cp "$ICON_ICNS" "$APP/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc signature, no entitlements (deliberately NOT sandboxed).
codesign --force -s - "$APP"

echo "✅ Build completata: $PWD/$APP"
echo "   Apri con: open $APP"
echo "   Se vedi «Respiro 2» nel menu, elimina le copie vecchie in /Applications e ~/Applications."
echo "   Ricorda: concedi Full Disk Access in Impostazioni di Sistema → Privacy e Sicurezza."
