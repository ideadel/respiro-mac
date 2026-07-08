# Repository settings (manuale)

Dopo il push, abilita su GitHub **Settings → General → Features**:

| Feature | Consiglio |
|---------|-----------|
| **Wiki** | On — poi `./scripts/publish-wiki.sh` |
| **Discussions** | On — Q&A community |
| **Issues** | On (già con template) |
| **Sponsorship** | Opzionale — Ko-fi è in FUNDING.yml |

## Etichette issue suggerite

Crea in **Issues → Labels** (se non esistono):

- `bug` — rosso
- `enhancement` — blu
- `documentation` — grigio
- `good first issue` — verde
- `help wanted` — giallo

## Branch protection (opzionale)

`main` → richiedi CI verde prima del merge.

## About (sidebar repo)

- **Description**: Utility macOS open source per pulizia e manutenzione. Offline, zero telemetria.
- **Website**: https://sevenweb.tv/apps/respiro/
- **Topics**: `macos`, `swift`, `swiftui`, `cleanup`, `disk-usage`, `uninstaller`, `open-source`, `privacy`
