# Sicurezza e privacy

## Privacy

- **Nessuna telemetria** — nessun analytics, crash reporter cloud, account
- **Dati locali** — storico pulizie e registro azioni restano sul Mac (`~/Library/Application Support/…`)
- **Aggiornamenti** — se Sparkle è attivo, contatta solo il feed su sevenweb.tv

## Sicurezza delle rimozioni

### Deny list

`DenyList` blocca percorsi di sistema (`/System`, app Apple in esecuzione, home root, symlink fuori scope). Ogni rimozione passa da `validateForRemoval`.

### Conferma utente

Nessun file viene rimosso senza selezione esplicita e conferma nel modulo (eccetto svuotamento Cestino, che ha dialogo dedicato).

### Registro

`ActionLogStore` annota path, byte, modulo, esito. Visibile in **Diario → Registro**, esportabile.

### Privilegi elevati

`PrivilegedRemovalService` usa AppleScript «with administrator privileges». I file finiscono nel Cestino dell'utente con `chown` corretto — non `rm -rf`.

## Segnalare problemi di sicurezza

Non aprire issue pubbliche. Leggi [SECURITY.md](https://github.com/ideadel/respiro-mac/blob/main/SECURITY.md).

## Cosa NON promettiamo

- Protezione antivirus
- Rimozione di malware
- Garanzia su estensioni di sistema bloccate da macOS/SIP

Respiro è un'utilità di **manutenzione consapevole**, non un sostituto di buon senso e backup.
