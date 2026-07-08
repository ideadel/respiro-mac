# Respiro — modello di distribuzione

Aggiornato 2026-07-08.

## Decisioni

| Voce | Scelta |
|---|---|
| Codice | **Open source** — licenza MIT, repo pubblico `ideadel/respiro-mac` |
| Binario | **Download gratis** da sevenweb.tv |
| Sostegno | **Donazione opzionale** su [Ko-fi](https://ko-fi.com/sevenwebtv) — nessuna funzione bloccata |
| Abbonamento / licenza a pagamento | **No** |
| Telemetria | **No** — validazione e uso 100% offline |

## Perché non Mac App Store

Sandbox incompatibile con Full Disk Access, Trasloco profondo, `purge` e manutenzione con privilegi admin.

## Release

1. `./release.sh` → zip + SHA256 + appcast Sparkle
2. Aggiornare `../sevenweb-portal/public/data/respiro.json` (versione, changelog)
3. Deploy del portale (Vercel)

## Notarizzazione (opzionale)

Per distribuzione senza “click destro → Apri”, usare Developer ID + `scripts/notarize.sh`.
