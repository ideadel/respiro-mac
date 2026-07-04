#!/bin/zsh
# Build Respiro.app and open it locally — no zip, no portale.
set -e
cd "$(dirname "$0")/.."
zsh build-app.sh
echo ""
echo "▶ Apro build/Respiro.app — controlla la sidebar sinistra (Respira, Spazio, App…)"
open build/Respiro.app
