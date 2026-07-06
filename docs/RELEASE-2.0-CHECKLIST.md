# Checklist release Respiro 2.0 (a pagamento)

Usare prima del cutover da `coming_soon` a vendita attiva.

## Prerequisiti

- [ ] Apple Developer Program attivo
- [ ] `DEVELOPER_ID` configurato in ambiente locale
- [ ] `notarytool store-credentials` → profilo `NOTARY_PROFILE=respiro`
- [ ] Lemon Squeezy: prodotto, prezzo 9 €, licenze, webhook (opzionale)
- [ ] [`docs/EULA.md`](EULA.md) linkato dal portale

## Build

```sh
DEVELOPER_ID="Developer ID Application: …" ./build-app.sh
DEVELOPER_ID="…" NOTARY_PROFILE=respiro ./scripts/notarize.sh
```

## App

- [ ] `CFBundleShortVersionString` → `2.0.0`
- [ ] Gate licenza attivo (`LicenseService.requiresLicense` su 2.x)
- [ ] Test attivazione chiave Lemon Squeezy / `./scripts/generate-license-key.sh`
- [ ] Sparkle appcast firmato

## Portale

- [ ] `respiro.json`: `"availability": "available"`, `checkoutUrl`, prezzo
- [ ] Ripristinare link download post-acquisto o pagina istruzioni
- [ ] Changelog 2.0 con messaggio onesto (perché a pagamento, grandfather 1.x)

## Comunicazione

- [ ] Annuncio: 1.x resta gratis per chi l'ha già; 2.0 una tantum, niente abbonamento
- [ ] Rimuovere copy «gratuito per sempre» rimasti
