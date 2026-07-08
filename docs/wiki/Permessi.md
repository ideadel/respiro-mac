# Permessi

## Accesso completo al disco (FDA)

Serve per leggere cartelle protette (`~/Library`, cache di sistema, ecc.). Respiro **non** invia quei dati in rete: li usa solo in locale per mostrarti cosa c'è.

Senza FDA vedrai meno elementi e messaggi espliciti sui limiti.

## Password di amministratore

Alcune operazioni richiedono privilegi root:

- Residui in `/Library` (sistema)
- Helper privilegiati, LaunchDaemons
- Disinstallazione di **estensioni di sistema** (es. camera virtuali)
- Spostamento di app in `/Applications` quando il sistema blocca il Cestino normale

Compare **un solo** prompt nativo macOS (password o Touch ID). I file vanno nel **tuo** Cestino, non vengono cancellati con `rm`.

## Estensioni di sistema

App come Insta360 o OBS installano estensioni camera registrate in macOS. Trasloco prova a disinstallarle con `systemextensionsctl` prima di rimuovere le cartelle.

Se un'estensione resta attiva, potrebbe servire:

1. Chiudere l'app collegata
2. Controllare **Impostazioni di Sistema → Generali → Accessori** (o Estensioni)
3. In casi rari, un **riavvio** del Mac

## Cosa Respiro non chiede

- Account o login
- Connessione internet per funzionare
- Accesso alla posizione, contatti, foto
