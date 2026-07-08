# Sicurezza

## Filosofia

Respiro può rimuovere file e disinstallare app. La sicurezza passa da:

- `DenyList` — percorsi e bundle di sistema mai toccabili
- Conferma esplicita prima di ogni rimozione
- Registro locale (`ActionLogStore`) di ogni operazione
- Zero telemetria — nessun dato inviato a server

## Segnalare una vulnerabilità

**Non aprire issue pubbliche** per problemi di sicurezza.

Scrivi a **security@sevenweb.tv** (o al contatto indicato su [sevenweb.tv](https://sevenweb.tv)) con:

1. Descrizione del problema
2. Passi per riprodurlo
3. Impatto stimato (es. bypass DenyList, escalation privilegi)
4. Versione di Respiro e macOS

Risposta attesa entro **7 giorni lavorativi**. Coordineremo fix e disclosure se necessario.

## Cosa consideriamo in scope

- Bypass di `DenyList.validateForRemoval`
- Rimozioni senza conferma utente
- Esecuzione di comandi privilegiati fuori dai flussi documentati
- Perdita o esfiltrazione dati verso rete

## Fuori scope

- Social engineering dell'utente che conferma volontariamente una rimozione
- Limiti del sandbox macOS / SIP su estensioni di sistema
- Build non ufficiali o modificate
