# Changelog Respiro

## 1.2.2 (2026-09-06)

### Panorama
- Si torna alla cartella superiore: pulsante Indietro (`⌘[`), percorso cliccabile e riga in lista
- Un tap apre la cartella (niente più doppio click)
- In cima, le tre voci più grandi da rivedere: **Si ricrea**, **Rivedi**, **Tieni**
- Non si sale più sopra casa o sopra il disco esterno

---

## 1.2.1 (2026-09-06)

### Aria
- Non propone più cache Apple protette (Safari, HomeKit, Family Circle, `com.apple.*`) che SIP impedisce di toccare
- Non elenca file inesistenti né i report della fixture di test
- Se un file è già sparito, la rimozione conta come riuscita — niente falsi errori
- Cache di sistema (`/Library/Caches`) tolte dalla lista: se non possiamo spostarle nel Cestino, non le mostriamo

---

## 1.2.0 (2026-07-08)

### Prodotto
- **Open source** (MIT) — [github.com/ideadel/respiro-mac](https://github.com/ideadel/respiro-mac)
- Download **gratuito** da [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro) — niente vendita, niente licenze
- Donazione facoltativa su [Ko-fi](https://ko-fi.com/sevenwebtv)
- Rimosso gate licenza e UI acquisto; Trasloco migliorato per estensioni di sistema

---

## 1.1.4 (2026-07-06)

### UI
- Fascia contestuale unificata in cima all'area principale: icona, titolo e guida per ogni sezione
- Sidebar stabile sotto i traffic lights — niente salti verticali al cambio voce
- Finestra immersiva senza barra superiore; «Apri Respiro» dalla menu bar riporta in primo piano senza duplicati
- Chip bar e sotto-tab coerenti (Zavorra, Diario)

---

## 1.1.3 (2026-07-04)

### UI
- Sidebar stabile (layout HStack) — voci Respira, Spazio, App, Energia, Diario sempre visibili
- Finestra immersiva: title bar trasparente nativa, aurora full-bleed, vetro sopra
- Scorciatoia Libera RAM su Respira (fix EnvironmentObject)

### Dev
- `./scripts/run-local.sh` — build e apri locale senza release

---

## 1.1.2 (2026-07-04)

### Fix
- Ripristinate voci menu macOS (rimosso hack `ApplicationBranding` su `mainMenu`)

---

## 1.1.1 (2026-07-04)

### Stabilità
- Fix lampeggio Trasloco (cache ViewModel, overlay loading, rimozione locale senza rescan)

### Feature
- **Vitali del Mac** su Respira — disco, RAM disponibile, carico CPU
- Scorciatoia **Libera RAM** (+ link Tagliando) nella card Vitali
- Menu bar: RAM disponibile e CPU oltre allo spazio disco
- Nome app forzato a **Respiro** nel menu (anche con bundle «Respiro 2.app»)

---

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

Release iniziale su sevenweb.tv — lessico proprio, home narrativa, trasparenza radicale.

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
