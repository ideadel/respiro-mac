# Respiro — modello commerciale (decisioni)

Documento di riferimento per il passaggio a pagamento. Aggiornato 2026-07-05.

## Decisioni

| Voce | Scelta |
|---|---|
| Modello | **Acquisto una tantum** — niente abbonamento |
| Canale | **Vendita diretta** da sevenweb.tv via Lemon Squeezy (non Mac App Store) |
| Prezzo lancio | **9 €** (poi 14 € senza urgenza artificiale) |
| Utenti 1.x | **Grandfathering** — chi ha 1.x gratis la tiene; da 2.0 serve licenza |
| Trial | No (semplicità + brand onesto) |
| Freemium | No |
| Validazione licenza | Offline-first, chiave in Keychain, zero telemetria in uso |
| Portale (fase attuale) | `availability: coming_soon` — niente download pubblico |

## Perché non App Store

Sandbox incompatibile con Full Disk Access, Trasloco profondo, `purge` e manutenzione con privilegi admin.

## Prossimi passi operativi

1. Apple Developer Program + Developer ID + notarizzazione (`scripts/notarize.sh`)
2. Account Lemon Squeezy + prodotto + webhook chiavi
3. Portale: `availability: available` + `checkoutUrl` + prezzo
4. Release **2.0.0** con gate licenza (1.x resta senza gate)
5. EULA e policy rimborsi 14 gg (EU)

## Generazione chiavi (sviluppo)

Formato: `RESPIRO-XXXX-XXXX-CC` (CC = checksum base36).

```sh
./scripts/generate-license-key.sh
```

Le chiavi Lemon Squeezy in produzione sostituiranno o integreranno questo schema.
