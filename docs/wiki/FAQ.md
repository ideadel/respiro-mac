# FAQ

## Respiro è gratis?

Sì. Codice [MIT](https://github.com/ideadel/respiro-mac/blob/main/LICENSE), download gratis da [sevenweb.tv](https://sevenweb.tv/apps/respiro). [Ko-fi](https://ko-fi.com/sevenwebtv) è facoltativo e non sblocca funzioni.

## Perché non è sull'App Store?

L'App Store sandbox non permette Full Disk Access, disinstallazione profonda, manutenzione con privilegi admin e altre funzioni centrali di Respiro.

## Respiro invia dati in rete?

No. Zero telemetria, zero account. L'unica rete opzionale è **Sparkle** per gli aggiornamenti, se abilitato nella build.

## Posso recuperare i file rimossi?

Quasi sempre sì: vanno nel **Cestino** (anche i file di sistema rimossi con password). Svuotare il Cestino è l'unica azione irreversibile esplicita.

## Perché alcune cartelle non compaiono?

Probabilmente manca **Accesso completo al disco**. Vedi [[Permessi]].

## Respiro può disinstallare se stesso?

No. Il bundle in esecuzione è escluso da Trasloco per evitare auto-rimozioni accidentali.

## Intel Mac?

Le build ufficiali sono **arm64** (Apple Silicon). Per Intel servirebbe una build separata; non è disponibile al momento.

## Come segnalo un bug?

[Issue su GitHub](https://github.com/ideadel/respiro-mac/issues/new?template=bug_report.yml) con versione, macOS, modulo e passi per riprodurre. Allega screenshot del **Registro** (Diario) se utile.

## Come contribuisco?

Leggi [CONTRIBUTING.md](https://github.com/ideadel/respiro-mac/blob/main/CONTRIBUTING.md) e apri una PR. Per idee grandi, apri prima una [Discussion](https://github.com/ideadel/respiro-mac/discussions).
