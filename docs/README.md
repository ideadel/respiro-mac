# Documentazione Respiro

Indice per sviluppatori e agenti AI che lavorano su **Respiro** (cartella `respiro`, repo `respiro-mac`).

## Knowledge graph (graphify)

Il grafo del codice Swift vive in `graphify-out/` (generato, non committato).

| Artefatto | Descrizione |
|---|---|
| `graphify-out/graph.json` | Grafo completo (598 nodi AST, 779 edge dopo clustering) |
| `graphify-out/GRAPH_REPORT.md` | Copia committata in [GRAPH_REPORT.md](GRAPH_REPORT.md) |
| `graphify-out/graph.html` | Visualizzazione interattiva |
| [GRAPH_TREE.html](GRAPH_TREE.html) | Albero D3 collapsible per cartelle |

Comandi: vedi [GRAPHIFY.md](GRAPHIFY.md).

## Guide

| Documento | Quando leggerlo |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Panoramica layer, navigazione, pipeline rimozione |
| [MODULES.md](MODULES.md) | Mapping enum → UI → scanner |
| [SERVICES.md](SERVICES.md) | Riferimento servizi in `Sources/Respiro/Services/` |
| [GRAPHIFY.md](GRAPHIFY.md) | Aggiornare e interrogare il grafo |
| [GRAPH_REPORT.md](GRAPH_REPORT.md) | Hub del grafo, god nodes, community |

## Design e copy (repo root)

| File | Contenuto |
|---|---|
| [docs/CHANGELOG.md](CHANGELOG.md) | Versioni |
| [docs/QA-CHECKLIST.md](QA-CHECKLIST.md) | Checklist pre-release |
| [design/COPY-GUARDRAILS.md](../design/COPY-GUARDRAILS.md) | Regole copy/UX |
| `design/CLAUDE-DESIGN-BRIEF.md` | Brief visivo |
| `design/SEVENWEB-PORTAL-PROMPT.md` | Prompt portale sevenweb.tv |

## Entry point agenti

- [AGENTS.md](../AGENTS.md) — riassunto operativo per Cursor/Claude/Codex
- `.cursor/rules/` — regole Cursor (graphify + contesto Respiro)

## Aggiornare la documentazione

1. Modifica codice Swift
2. `graphify update Sources/Respiro`
3. `graphify cluster-only Sources/Respiro --no-label` (se serve rigenerare report)
4. Copia `graphify-out/GRAPH_REPORT.md` → `docs/GRAPH_REPORT.md` se cambia in modo rilevante
