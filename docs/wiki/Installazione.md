# Installazione

## Requisiti

- macOS **13** o successivo
- Mac **Apple Silicon** (arm64)
- Command Line Tools (solo se compili da sorgente)

## Download

1. Vai su [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro)
2. Clicca **Scarica** e apri lo zip
3. Trascina `Respiro.app` in **Applicazioni**

Verifica integrità: sulla pagina prodotto trovi l'hash **SHA256** del file zip.

## Primo avvio (firma ad-hoc)

Le build distribuite da sevenweb.tv sono firmate **ad-hoc** (non notarizzate Apple):

1. **Click destro** su `Respiro.app` → **Apri**
2. Conferma nel dialogo di sicurezza
3. Ai successivi avvii basta un doppio click

## Accesso completo al disco

Senza questo permesso alcune cartelle restano illeggibili e Respiro te lo dice chiaramente — **non** finge che tutto sia pulito.

1. **Impostazioni di Sistema** → **Privacy e sicurezza** → **Accesso completo al disco**
2. Aggiungi **Respiro** (icona `+` se non compare)
3. Riavvia Respiro

## Aggiornamenti

Se la build include Sparkle, usa **Impostazioni → Controlla aggiornamenti** oppure il menu dell'app. Gli aggiornamenti arrivano da sevenweb.tv, non dall'App Store.

## Da sorgente

Vedi [[Sviluppo]] o [CONTRIBUTING.md](https://github.com/ideadel/respiro-mac/blob/main/CONTRIBUTING.md).
