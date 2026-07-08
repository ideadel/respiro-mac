#!/usr/bin/env zsh
# Pubblica docs/wiki/ sulla GitHub Wiki del repository.
# Prerequisiti:
#   1. Wiki abilitata: repo Settings → Features → Wiki
#   2. gh auth login (o accesso git al remote wiki)
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-ideadel/respiro-mac}"
WIKI_URL="https://github.com/${REPO}.wiki.git"
SRC="$(cd "$(dirname "$0")/.." && pwd)/docs/wiki"
TMP=$(mktemp -d)

cleanup() { rm -rf "$TMP" }
trap cleanup EXIT

echo "▸ Clone wiki da $WIKI_URL"
if ! git clone "$WIKI_URL" "$TMP" 2>/dev/null; then
  echo "❌ Impossibile clonare la wiki. Abilitala in Settings → Features → Wiki"
  exit 1
fi

echo "▸ Copia pagine (escluso README.md)"
for f in "$SRC"/*.md(N); do
  [[ "$(basename "$f")" == README.md ]] && continue
  cp "$f" "$TMP/"
done

cd "$TMP"
if git diff --quiet && git diff --cached --quiet; then
  echo "✅ Wiki già aggiornata"
  exit 0
fi

git add -A
git commit -m "Sync da docs/wiki ($(date +%Y-%m-%d))"
git push
echo "✅ Wiki pubblicata: https://github.com/${REPO}/wiki"
