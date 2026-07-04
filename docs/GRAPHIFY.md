# Graphify su Respiro

[Graphify](https://pypi.org/project/graphifyy/) indicizza il codice Swift via AST e produce un grafo navigabile per agenti AI.

## Stato attuale

| Metrica | Valore |
|---|---|
| Root scansione | `Sources/Respiro` |
| Output | `graphify-out/` (repo root) |
| Nodi | ~552 (clustered) / ~598 (raw AST) |
| Edge | ~779 |
| Community | 36 |
| Commit grafo | vedi header in [GRAPH_REPORT.md](GRAPH_REPORT.md) |

## Comandi essenziali

```sh
# Dalla root del repo cleanmyMela

# Aggiornare dopo modifiche Swift (zero costo API)
graphify update Sources/Respiro

# Rigenerare community + report (senza LLM per i nomi)
graphify cluster-only Sources/Respiro --no-label --graph graphify-out/graph.json

# Interrogare il grafo
graphify query "come funziona LeftoverFinder?" --graph graphify-out/graph.json
graphify path "UninstallerView" "DenyList" --graph graphify-out/graph.json
graphify explain "CleanupEngine" --graph graphify-out/graph.json
graphify affected "DenyList" --graph graphify-out/graph.json

# Albero HTML per cartelle
graphify tree --graph graphify-out/graph.json --output docs/GRAPH_TREE.html --label Respiro --root Sources/Respiro
```

## Primo setup (macchina nuova)

```sh
pipx install graphifyy   # o: pip install graphifyy
cd /path/to/cleanmyMela
graphify update Sources/Respiro
graphify cluster-only Sources/Respiro --no-label --graph graphify-out/graph.json
graphify cursor install  # scrive .cursor/rules/graphify.mdc
```

`graphify extract` richiede API key LLM solo se ci sono doc/immagini da estrarre semanticamente. Il corpus Swift puro basta con `update`.

## File generati

```
graphify-out/
├── graph.json          # grafo machine-readable (gitignored)
├── graph.html          # viz interattiva (gitignored)
├── GRAPH_REPORT.md     # report umano → copia in docs/
├── cache/              # cache AST
└── .graphify_root      # punta a Sources/Respiro
```

Commitare in git:

- `docs/GRAPH_REPORT.md` — snapshot report per agenti senza rigenerare
- `docs/GRAPH_TREE.html` — navigazione visuale leggera
- `AGENTS.md`, `docs/*.md` — guide scritte a mano

## Integrazione Cursor

`.cursor/rules/graphify.mdc` (generato da `graphify cursor install`):

- Obbliga `graphify query/path/explain` **prima** di Read/Grep/Glob su codice sconosciuto
- Dopo modifiche: `graphify update Sources/Respiro`

`.cursor/rules/respiro.mdc` — contesto prodotto (copy, moduli, vincoli).

## Verificare staleness

```sh
git rev-parse HEAD
# confronta con "Built from commit" in GRAPH_REPORT.md
```

Se diverso → `graphify update Sources/Respiro`.

## God nodes utili per onboarding

1. `LeftoverCategory` — tassonomia disinstallatore
2. `Module` / `Area` — routing
3. `CleanupListViewModel` — pattern pulizia
4. `LeftoverReviewViewModel` — disinstallatore
5. `DenyList` — sicurezza rimozioni

Vedi sezione completa in [GRAPH_REPORT.md](GRAPH_REPORT.md).

Con API key cloud (Anthropic/Gemini/OpenAI):

```sh
graphify label Sources/Respiro --graph graphify-out/graph.json
```

Con Ollama locale, se `graphify label` fallisce sul parse JSON, scrivere le label in `graphify-out/.graphify_labels.json` e rigenerare:

```sh
graphify cluster-only Sources/Respiro --graph graphify-out/graph.json
```

Le community attuali hanno label semantiche (es. "Leftover Discovery Engine", "Safety Deny List") — vedi [GRAPH_REPORT.md](GRAPH_REPORT.md).
