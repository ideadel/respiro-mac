#!/bin/zsh
# Fixture per il self-test del disinstallatore:
#   scripts/make-fixture.sh create   crea l'app finta e i residui utente
#   scripts/make-fixture.sh clean    rimuove tutto
# Le posizioni di sistema (/Library) hanno una sezione sudo opzionale:
#   scripts/make-fixture.sh create-system / clean-system
set -euo pipefail

BUNDLE_ID="com.respirotest.fixture"
APP="$HOME/Applications/RespiroFixture.app"
LIB="$HOME/Library"

USER_PATHS=(
  "$LIB/Preferences/com.respirotest.fixture.plist"
  "$LIB/Preferences/ByHost/com.respirotest.fixture.ABC123.plist"
  "$LIB/Caches/com.respirotest.fixture"
  "$LIB/Caches/Respirotest"
  "$LIB/Application Support/RespiroFixture"
  "$LIB/Logs/com.respirotest.fixture.log"
  "$LIB/Logs/DiagnosticReports/RespiroFixture-2026-07-01-120000.ips"
  "$LIB/Saved Application State/com.respirotest.fixture.savedState"
  "$LIB/Containers/com.respirotest.fixture"
  "$LIB/Containers/com.respirotest.helper"
  "$LIB/Group Containers/ABC123.com.respirotest.fixture"
  "$LIB/LaunchAgents/respirotest-agent.plist"
  "$LIB/HTTPStorages/com.respirotest.fixture"
  "$LIB/WebKit/com.respirotest.fixture"
  "$LIB/Cookies/com.respirotest.fixture.binarycookies"
  "$LIB/Application Scripts/com.respirotest.fixture"
  "$LIB/Services/RespiroFixture Helper.workflow"
  "$LIB/QuickLook/RespiroFixture.qlgenerator"
  "$LIB/PreferencePanes/RespiroFixture.prefPane"
  "$LIB/Internet Plug-Ins/RespiroFixture.plugin"
  "$LIB/Audio/Plug-Ins/Components/RespiroFixture.component"
)
# Controlli negativi: NON devono mai essere trovati dal finder.
NEGATIVE_PATHS=(
  "$LIB/Application Support/RespiroOther"
  "$LIB/Preferences/com.othervendor.unrelated.plist"
)

info_plist() { # $1 = bundle id, $2 = name
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$1</string>
  <key>CFBundleName</key><string>$2</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
</dict></plist>
PLIST
}

create() {
  echo "Creo fixture in $APP…"
  mkdir -p "$APP/Contents/MacOS"
  info_plist "$BUNDLE_ID" "RespiroFixture" > "$APP/Contents/Info.plist"
  printf '#!/bin/sh\nsleep 3600\n' > "$APP/Contents/MacOS/RespiroFixture"
  chmod +x "$APP/Contents/MacOS/RespiroFixture"

  # LoginItem helper con bundle id diverso dal principale (testa gli aux id).
  local HELPER="$APP/Contents/Library/LoginItems/RespiroFixtureHelper.app"
  mkdir -p "$HELPER/Contents"
  info_plist "com.respirotest.helper" "RespiroFixtureHelper" > "$HELPER/Contents/Info.plist"

  # Privileged helper: per convenzione il filename è il label.
  mkdir -p "$APP/Contents/Library/LaunchServices"
  touch "$APP/Contents/Library/LaunchServices/com.respirotest.privhelper"

  echo "Pianto i residui utente…"
  # Alcune cartelle (es. ~/Library/Cookies) sono protette da TCC: senza Full
  # Disk Access per il terminale il singolo residuo viene saltato, e il
  # self-test lo ignora perché controlla solo i percorsi esistenti.
  for p in "${USER_PATHS[@]}" "${NEGATIVE_PATHS[@]}"; do
    {
      mkdir -p "$(dirname "$p")"
      case "$p" in
        *.plist|*.log|*.ips|*.binarycookies) echo "fixture" > "$p" ;;
        *) mkdir -p "$p"; echo "fixture" > "$p/data" ;;
      esac
    } 2>/dev/null || echo "  saltato (permessi TCC): $p"
  done

  # Il LaunchAgent matcha solo tramite la chiave Label del plist.
  cat > "$LIB/LaunchAgents/respirotest-agent.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.respirotest.fixture.agent</string>
  <key>ProgramArguments</key><array><string>/usr/bin/true</string></array>
</dict></plist>
PLIST
  echo "Fatto. Ora: ./build/Respiro.app/Contents/MacOS/Respiro --selftest-uninstaller"
}

clean() {
  echo "Rimuovo fixture e residui…"
  rm -rf "$APP"
  for p in "${USER_PATHS[@]}" "${NEGATIVE_PATHS[@]}"; do rm -rf "$p"; done
  echo "Fatto."
}

create_system() {
  echo "Pianto residui di sistema (richiede sudo)…"
  sudo mkdir -p "/Library/Application Support/RespiroFixture" \
               "/Library/Caches/com.respirotest.fixture" \
               "/Library/PrivilegedHelperTools"
  sudo touch "/Library/PrivilegedHelperTools/com.respirotest.privhelper"
  sudo tee "/Library/LaunchDaemons/respirotest-daemon.plist" >/dev/null <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.respirotest.privhelper</string>
  <key>ProgramArguments</key><array><string>/usr/bin/true</string></array>
</dict></plist>
PLIST
  echo "Fatto."
}

clean_system() {
  sudo rm -rf "/Library/Application Support/RespiroFixture" \
              "/Library/Caches/com.respirotest.fixture" \
              "/Library/PrivilegedHelperTools/com.respirotest.privhelper" \
              "/Library/LaunchDaemons/respirotest-daemon.plist"
  echo "Fatto."
}

case "${1:-}" in
  create) create ;;
  clean) clean ;;
  create-system) create_system ;;
  clean-system) clean_system ;;
  *) echo "uso: $0 create | clean | create-system | clean-system"; exit 2 ;;
esac
