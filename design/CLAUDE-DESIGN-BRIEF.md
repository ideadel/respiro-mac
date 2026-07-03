# CleanMyMela — Brief di design per Claude Design

## Il prodotto

CleanMyMela è un'app **macOS nativa (SwiftUI)** di pulizia e manutenzione del sistema: un'alternativa personale, privata e 100% locale a CleanMyMac X. Zero rete, zero telemetria, zero account. Il nome è un gioco di parole: *CleanMyMac → CleanMyMela* (mela = Apple).

**Personalità del brand**: pulita, affidabile, leggera, un po' giocosa (il nome lo è). NON aggressiva o "da antivirus": niente rossi allarmistici come colore dominante, niente dark pattern. L'app sposta i file nel Cestino, non li distrugge: la sensazione deve essere di ordine e controllo, non di pericolo.

**Riferimenti estetici**: CleanMyMac X (MacPaw) per la qualità, ma NON va copiata — serve un'identità originale. Gradite le atmosfere delle utility macOS moderne: molta aria, gerarchia tipografica chiara, glassmorphism leggero dove ha senso.

---

## Deliverable richiesti

### 1. Icona app (priorità alta)
- **Master 1024×1024 px, PNG con trasparenza**, forma squircle macOS (il sistema NON applica la maschera automaticamente: la squircle con ombra va disegnata dentro il canvas, come da Human Interface Guidelines macOS).
- Concept suggerito (libero di proporre alternative): una **mela** stilizzata combinata con un elemento di pulizia/brillantezza (scintilla, scia, riflesso). Evitare: scope/spazzoloni letterali, ingranaggi, scudi da antivirus.
- Deve funzionare a 16×16 px (menu bar e Finder): servono forme semplici e silhouette riconoscibile.
- Palette dell'icona = base della palette dell'app.
- Consegna: PNG 1024 master (dalle altre misure 16/32/64/128/256/512 @1x e @2x genero io l'.icns).

### 2. Sistema visivo dell'interfaccia
- **Palette completa** (light + dark mode) in esadecimale: colore accent, sfondi, superfici/card, testo primario/secondario, semantici (successo, warning, pericolo).
- **Icone dei 10 moduli** della sidebar: indicare per ciascuno un SF Symbol (preferito, perché gratis in SwiftUI) oppure fornire asset SVG/PNG template monocromatici.
- **Stile card e componenti**: raggio angoli, ombre/materiali, spaziature.
- Mockup (immagini) delle 4 schermate chiave: Smart Scan, Pulizia sistema, Disinstallatore, Space Lens.

---

## Vincoli tecnici (importanti)

- SwiftUI puro su **macOS 13+**: niente web view, niente Lottie. Le proposte devono essere realizzabili con: `Color` hex custom, SF Symbols, gradienti, `RoundedRectangle`, materiali di sistema (`.ultraThinMaterial` ecc.), animazioni SwiftUI semplici.
- Font: **SF Pro di sistema** (niente font custom). Si può giocare con pesi e dimensioni.
- Deve funzionare in **light e dark mode** (definire entrambe le varianti).
- Layout: finestra minima 900×560, `NavigationSplitView` con sidebar sinistra (min 180 pt).
- L'app ha anche una **icona in menu bar** (attualmente SF Symbol "sparkles"): proporre un glifo template monocromatico 22×22 pt.

---

## Inventario delle schermate (stato attuale, da ridisegnare)

### Struttura globale
Sidebar sinistra con 6 sezioni e 10 moduli:

| Sezione | Moduli (icona SF Symbol attuale) |
|---|---|
| Riepilogo | Smart Scan (`sparkles`) |
| Pulizia | Pulizia sistema (`internaldrive`), Cestino (`trash`) |
| Applicazioni | Disinstallatore (`xmark.bin`) |
| Velocità | Avvio (`power`), Manutenzione (`wrench.and.screwdriver`) |
| Spazio | File grandi (`doc.badge.clock`), Duplicati (`doc.on.doc`), Space Lens (`circle.grid.2x2`) |
| Sicurezza | Protezione (`shield`) |

### 1. Smart Scan (schermata di apertura — la "hero")
- Stato iniziale: icona grande, titolo, sottotitolo, bottone "Analizza" prominente.
- Durante: progress. Dopo: **4 card cliccabili** in riga (Pulizia sistema con GB trovati, Cestino con dimensione, Avvio con conteggio, Protezione con anomalie). Le card portano ai rispettivi moduli.
- È la schermata da rendere memorabile: qui c'è più libertà creativa (illustrazione, gradiente, animazione dell'analisi).

### 2. Pulizia sistema / File grandi / Duplicati / Protezione (layout condiviso "CleanupModuleView")
- Header: titolo + sottotitolo a sinistra; a destra bottoni "Tutto/Niente/Pulisci", contatore "N su M · dimensione", "Riesegui scansione".
- Corpo: lista raggruppata in sezioni (nome gruppo + dimensione totale a destra), righe con: checkbox, nome file, percorso/dettaglio in caption, eventuale lucchetto 🔒 (richiede admin), badge arancione "solo nome" (bassa confidenza, solo nel disinstallatore), dimensione o spinner a destra.
- Stati: scansione (progress), lista vuota (messaggio centrato), rimozione (progress), esito (successo verde / parziale arancione + lista errori + "OK").
- Nota Duplicati: in ogni gruppo la prima riga ha dettaglio "Copia da mantenere" ed è deselezionata — merita una distinzione visiva.

### 3. Cestino
- Vista centrata: icona, dimensione in grande (largeTitle), conteggio elementi, bottone distruttivo "Svuota il Cestino…" con conferma, avviso arancione "definitivo e non recuperabile".

### 4. Disinstallatore (due pannelli, HSplitView)
- Sinistra: campo ricerca + lista app (nome + bundle id in caption).
- Destra: header con nome app/versione + bottone "Disinstalla…" e totale selezionato; lista residui per categoria (Preferenze, Cache, Application Support, Log, Container, LaunchAgents…) con checkbox, lucchetti e badge come sopra.
- Sheet di conferma: riepilogo N elementi/dimensione, avviso lucchetto se servono privilegi, nota "recuperabile dal Cestino".
- Vista esito: icona verde/arancione, lista per-elemento con ✓/✗, bottoni "Mostra nel Cestino" e "Fine".

### 5. Avvio
- Lista in sezioni (Agenti utente / Agenti di sistema / Daemon di sistema): label + badge grigio "disattivato", percorso eseguibile in caption, lucchetto, bottoni "Attiva/Disattiva" e cestino per riga.

### 6. Manutenzione
- Lista di 5 attività: titolo + lucchetto se serve admin, descrizione in caption, bottone "Esegui" a destra, esito ✓ verde / ✗ rosso per riga.

### 7. Space Lens
- Header: barra di utilizzo del volume (usati/liberi), breadcrumb del percorso con bottone su ↑, "Aggiorna".
- Lista: icona cartella/file, nome, **barra proporzionale alla dimensione** (elemento chiave da valorizzare visivamente), dimensione. Doppio click per scendere nelle cartelle.

---

## Cosa restituire, in pratica

1. PNG 1024×1024 dell'icona (± varianti/proposte).
2. Glifo menu bar template 22×22.
3. Tabella palette light/dark in hex.
4. Lista SF Symbol (o asset) per i 10 moduli.
5. Mockup delle 4 schermate chiave.
6. Note di stile: raggi, spaziature, materiali, micro-animazioni suggerite (descritte a parole, verranno implementate in SwiftUI).
