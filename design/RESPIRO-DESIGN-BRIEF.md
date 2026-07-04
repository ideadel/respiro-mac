# Respiro — Design Brief

Utility macOS nativa (SwiftUI) per pulizia e manutenzione locale. Identità: **onesta, reversibile, leggera, un po' giocosa** — mai scare-marketing.

Riferimenti: CleanMyMac X per qualità funzionale, **non** per copy o UI. Atmosfera utility macOS moderna: aria, tipografia chiara, glass leggero.

Vincoli tecnici: SwiftUI puro, macOS 13+, SF Pro, SF Symbols, min 900×560, `NavigationSplitView` con 5 aree sidebar.

## Personalità visiva

| Elemento | Linea guida |
|---|---|
| Mascot (`MelaMascot`) | Presente in attesa (scan, rimozione) e empty state — respira, non allarme |
| Aurora | Sfondo detail pane; attenuata su liste lunghe (`AuroraBackground(subdued:)`) |
| Colore accent | Verde Respiro — junk mai rosso |
| Motion | Spring su chip/checkbox; mai pulse su conteggi o progress teatrali |
| Glass | Card e sidebar con `.ultraThinMaterial` |

## Architettura UI (5 aree)

| Area | Moduli |
|---|---|
| Respira | Home narrativa |
| Spazio | Aria, Cestino, Zavorra, Panorama |
| App | Trasloco |
| Energia | Avvio, Tagliando, Guardia |
| Diario | Statistiche, Scia, Registro |

## Schermate chiave

1. **Respira** — mascot, headline onesta, CTA singola, link findings
2. **CleanupModuleView** — Aria, Guardia, Zavorra: scan → checkbox → Cestino; overlay removing con mascot
3. **Trasloco** — split app / residui; lista stabile durante rimozione
4. **Diario / Scia** — timeline giornaliera per modulo
5. **Panorama** — mappa disco con guardrail Cestino

## Copy

Vedi [`COPY-GUARDRAILS.md`](COPY-GUARDRAILS.md). Lessico app: Respira, Aria, Trasloco… — vietati nomi CleanMyMac.

## Icona

Master 1024×1024, squircle disegnata nel canvas. Mela stilizzata + scintilla/scia. Menu bar: glyph template 22×22 (`menubar-glyph.png`).
