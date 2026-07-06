# QA Checklist Respiro

Checklist manuale (~15 min) da eseguire prima di ogni release. Automazione: `./scripts/verify.sh`.

## Build e self-test

- [ ] `./scripts/verify.sh` exit 0
- [ ] `./build-app.sh` completa senza errori
- [ ] App si apre con click destro → Apri (firma ad-hoc)

## Permessi

- [ ] **Senza** Full Disk Access: moduli mostrano limiti onesti, mai "tutto pulito" falso
- [ ] **Con** Full Disk Access: Aria e Trasloco trovano residui reali
- [ ] Impostazioni → sezione Accesso completo al disco mostra stato corretto

## Trasloco (priorità bugfix)

- [ ] Lista app: nessun lampeggio durante caricamento residui
- [ ] Dimensioni residui appaiono insieme, non riga per riga
- [ ] Durante rimozione: lista resta visibile con overlay, non sparisce
- [ ] Dopo disinstallazione: app rimossa dalla lista sinistra senza rescan completo
- [ ] App Apple (`com.apple.*`): nessun residuo proposto
- [ ] Cancel elevation: banner chiaro, nessun crash

## Moduli pulizia (Aria, Zavorra, Guardia)

- [ ] Scan → lista stabile (no flicker size)
- [ ] Rimozione: overlay con mascot, lista disabilitata
- [ ] File finiscono nel Cestino (recuperabili)
- [ ] Guardia: copy "non è un antivirus" visibile

## Diario

- [ ] Registro: ogni rimozione registrata file per file
- [ ] Scia: timeline per giorno e modulo
- [ ] Export CSV/JSON funziona

## Altro

- [ ] Respira: scan home, link findings
- [ ] Menu bar: spazio libero visibile
- [ ] Light e dark mode leggibili
- [ ] Ko-fi solo in About + messaggio post-pulizia (no modale invasiva)

## Release

- [ ] `./release.sh` → zip + SHA256
- [ ] Aggiornare `../sevenweb-portal/public/data/respiro.json` (versione + changelog)
- [ ] `graphify update Sources/Respiro` se codice Swift cambiato
