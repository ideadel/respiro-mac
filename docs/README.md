# Documentazione Respiro

## Wiki (utenti e contributor)

| Pagina | Contenuto |
|--------|-----------|
| [wiki/Home.md](wiki/Home.md) | Indice wiki |
| [wiki/Installazione.md](wiki/Installazione.md) | Download, permessi, primo avvio |
| [wiki/Moduli.md](wiki/Moduli.md) | Guida ai moduli |
| [wiki/Permessi.md](wiki/Permessi.md) | FDA, admin, estensioni |
| [wiki/FAQ.md](wiki/FAQ.md) | Domande frequenti |
| [wiki/Sviluppo.md](wiki/Sviluppo.md) | Build e test |
| [wiki/Sicurezza-e-privacy.md](wiki/Sicurezza-e-privacy.md) | Deny list, registro |

Pubblicazione su GitHub Wiki: `./scripts/publish-wiki.sh`

## Riferimento tecnico

| File | Contenuto |
|------|-----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer, flussi, dipendenze |
| [MODULES.md](MODULES.md) | Moduli, view, view model |
| [SERVICES.md](SERVICES.md) | Servizi e responsabilità |
| [GRAPH_REPORT.md](GRAPH_REPORT.md) | Snapshot struttura codice |
| [QA-CHECKLIST.md](QA-CHECKLIST.md) | Checklist pre-release |
| [CHANGELOG.md](CHANGELOG.md) | Versioni |
| [MONETIZATION.md](MONETIZATION.md) | Open source + Ko-fi |
| [EULA.md](EULA.md) | Note d'uso binario |

## Entry point

- [CONTRIBUTING.md](../CONTRIBUTING.md) — build, PR, vincoli
- [design/COPY-GUARDRAILS.md](../design/COPY-GUARDRAILS.md) — copy e UX

## Release

1. `./scripts/verify.sh`
2. Bump `Resources/Info.plist`
3. `./release.sh`
4. Aggiorna `../sevenweb-portal/public/data/respiro.json`
