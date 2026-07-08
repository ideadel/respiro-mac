# Wiki Respiro

Documentazione orientata agli **utenti** e ai **contributori**. Le pagine vivono in questo repo (`docs/wiki/`) così restano versionate insieme al codice.

## Indice

| Pagina | Contenuto |
|--------|-----------|
| [Home](Home.md) | Panoramica e link rapidi |
| [Installazione](Installazione.md) | Download, firma ad-hoc, Full Disk Access |
| [Moduli](Moduli.md) | Cosa fa ogni sezione dell'app |
| [Permessi](Permessi.md) | FDA, password admin, estensioni di sistema |
| [FAQ](FAQ.md) | Domande frequenti |
| [Sviluppo](Sviluppo.md) | Build, test, release |
| [Sicurezza e privacy](Sicurezza-e-privacy.md) | Deny list, registro, zero telemetria |

## GitHub Wiki (opzionale)

Puoi abilitare la **Wiki** del repository su GitHub e pubblicare queste pagine:

```sh
./scripts/publish-wiki.sh
```

Lo script clona `respiro-mac.wiki`, copia i file da `docs/wiki/` e fa push. Richiede wiki abilitata e `gh auth login`.

In alternativa, leggi direttamente i file `.md` su GitHub: funzionano come wiki in-repo.
