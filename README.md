# Respiro

Utility macOS per pulizia e manutenzione del sistema — 100% locale, zero rete, zero telemetria.

Distribuito gratuitamente su [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro) (mirror: [sevenweb-portal.vercel.app](https://sevenweb-portal.vercel.app/apps/respiro/)).

Sorgente privato: [github.com/ideadel/respiro-mac](https://github.com/ideadel/respiro-mac)

## Build

Richiede solo i Command Line Tools (nessun Xcode):

```sh
./build-app.sh
open build/Respiro.app
```

**Primo avvio**: concedi **Accesso completo al disco** in Impostazioni di Sistema → Privacy e Sicurezza → Accesso completo al disco.

**Firma ad-hoc**: al primo avvio, click destro sull'app → Apri.

## Release

```sh
./release.sh
```

Copia lo zip in `../sevenweb-portal/public/downloads/respiro/` per il deploy del portale.

## Moduli

Smart Scan, Pulizia sistema, Cestino, Disinstallatore, Avvio, Manutenzione, File grandi, Duplicati, Space Lens, Protezione, Menu bar.

## Licenza

Vedi [LICENSE](LICENSE). Uso gratuito; il sorgente resta privato.
