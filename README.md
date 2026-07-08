# Respiro

**Il tuo Mac non dovrebbe pagare un canone per respirare.**

Respiro è un'utility macOS per pulizia, disinstallazione e manutenzione — **100% offline**, senza telemetria e senza account. È **open source** ([MIT](LICENSE)) e la distribuisce **[SevenWeb](https://sevenweb.tv)**.

<p align="center">
  <a href="https://sevenweb.tv/apps/respiro/">
    <img src="https://sevenweb.tv/assets/screenshots/respira.png" alt="Respiro — schermata Respira" width="720">
  </a>
</p>

<p align="center">
  <a href="https://sevenweb.tv/apps/respiro/"><img src="https://img.shields.io/badge/Scarica-sevenweb.tv-34C87E?style=for-the-badge" alt="Scarica da sevenweb.tv"></a>
  <a href="https://github.com/ideadel/respiro-mac"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT"></a>
  <a href="https://github.com/ideadel/respiro-mac/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ideadel/respiro-mac/ci.yml?branch=main&style=for-the-badge" alt="CI"></a>
</p>

---

## Scarica Respiro

Le build ufficiali, il changelog e l'hash **SHA256** sono sul portale — non qui su GitHub.

| | |
|---|---|
| **Pagina prodotto** | [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro/) |
| **Download diretto** | [Respiro 1.2.0 (arm64)](https://sevenweb.tv/downloads/respiro/Respiro-1.2.0-macOS-arm64.zip) |
| **Catalogo software** | [sevenweb.tv/apps](https://sevenweb.tv/apps/) |
| **Chi sono / SevenWeb** | [sevenweb.tv/about](https://sevenweb.tv/about/) |

**Requisiti:** macOS 13+, Apple Silicon (arm64).

**Primo avvio:** click destro su `Respiro.app` → **Apri** (firma ad-hoc). Poi concedi **Accesso completo al disco** in Impostazioni di Sistema → Privacy e sicurezza.

Guida passo passo: [docs/wiki/Installazione.md](docs/wiki/Installazione.md)

---

## Cosa fa

Respiro ti aiuta a capire cosa occupa spazio sul Mac e a liberarlo **solo dove decidi tu**. Niente rimozioni automatiche, niente allarmismi: ogni file passa dal Cestino (recuperabile) e ogni azione finisce nel **Diario**.

| Area | Moduli |
|------|--------|
| **Respira** | Home — disco, RAM, CPU e panoramica leggera |
| **Spazio** | **Aria** (cache), **Cestino**, **Zavorra** (ingombranti e doppioni), **Panorama** (mappa disco) |
| **App** | **Trasloco** — disinstalla un'app e rivedi i residui prima di toglierli |
| **Energia** | **Avvio**, **Tagliando**, **Guardia** |
| **Diario** | Statistiche, registro file per file, timeline **Scia** |

Approfondimenti: [docs/wiki/Moduli.md](docs/wiki/Moduli.md)

---

## Perché esiste

Respiro nasce su [SevenWeb](https://sevenweb.tv) con un'idea semplice: **software fatto a mano, che resta tuo** — senza abbonamenti, senza telemetria, senza account.

- **Trasparenza** — confermi tu cosa rimuovere; niente numeri gonfiati
- **Privacy** — tutto resta sul Mac; nessun dato inviato a server
- **Open source** — puoi leggere, verificare e contribuire al [codice](https://github.com/ideadel/respiro-mac)
- **Gratis** — il download dal portale non costa nulla

Se Respiro ti è utile, puoi offrire un caffè su **[Ko-fi](https://ko-fi.com/sevenwebtv)** — è facoltativo e **non sblocca funzioni**.

---

## Per gli utenti

| Bisogno | Dove |
|---------|------|
| Scaricare / aggiornamenti | [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro/) |
| Domande d'uso | [GitHub Discussions](https://github.com/ideadel/respiro-mac/discussions) |
| Segnalare un bug | [Issue](https://github.com/ideadel/respiro-mac/issues/new?template=bug_report.yml) |
| Wiki | [docs/wiki/Home.md](docs/wiki/Home.md) |
| Supporto | [SUPPORT.md](SUPPORT.md) |

---

## Per chi sviluppa

Questo repository contiene il sorgente Swift/SwiftUI. Il sito e i binari release vivono sul [portale SevenWeb](https://sevenweb.tv) (repo separato).

```sh
git clone https://github.com/ideadel/respiro-mac.git
cd respiro-mac
./build-app.sh          # → build/Respiro.app
./scripts/verify.sh     # self-test
```

Release ufficiale (zip + checksum → portale):

```sh
./release.sh   # copia in ../sevenweb-portal/public/downloads/respiro/
```

Leggi [CONTRIBUTING.md](CONTRIBUTING.md) prima di aprire una PR. Architettura: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Licenza

Codice sorgente: [MIT](LICENSE).

Il binario scaricato da [sevenweb.tv](https://sevenweb.tv/apps/respiro/) è gratuito. Note d'uso: [docs/EULA.md](docs/EULA.md).

---

<p align="center">
  <a href="https://sevenweb.tv">sevenweb.tv</a> ·
  <a href="https://sevenweb.tv/apps/respiro/">Respiro</a> ·
  <a href="https://github.com/ideadel/respiro-mac">GitHub</a> ·
  <a href="https://ko-fi.com/sevenwebtv">Ko-fi</a>
</p>
