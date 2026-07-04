# Changelog Respiro

## 1.1.0 (2026-07-04)

### Stabilità
- Fix lampeggio Trasloco: batch update dimensioni residui, lista app con id stabile, rimozione locale senza rescan
- Overlay removing in Trasloco e moduli pulizia (lista resta visibile)
- Batch scan in Aria, Zavorra, Guardia (CleanupListViewModel)

### Feature
- **Scia** — timeline visiva in Diario (7/30 giorni, export CSV/JSON)
- Impostazioni: stato Accesso completo al disco + link Impostazioni di Sistema

### QA
- `./scripts/verify.sh` — build + self-test CLI
- `--selftest-denylist`, `--selftest-cleanup`
- [`docs/QA-CHECKLIST.md`](QA-CHECKLIST.md)

### Docs
- [`design/RESPIRO-DESIGN-BRIEF.md`](../design/RESPIRO-DESIGN-BRIEF.md)
- Aurora attenuata su schermate con liste lunghe

---

## 1.0.0 (2026-07-04)

Release iniziale Respiro 2.0 — lessico proprio, home narrativa, trasparenza radicale.

### Portale (sevenweb-portal)

Aggiornare `public/data/respiro.json`:

```json
"version": "1.1.0",
"changelog": [
  {
    "version": "1.1.0",
    "date": "2026-07-04",
    "it": ["Fix lampeggio Trasloco", "Scia in Diario", "Self-test e QA"],
    "en": ["Uninstaller flicker fix", "Scia timeline in Diary", "Self-tests and QA"]
  }
]
```
