# Respiro — Guardrail di copy e UX

Regole vincolanti per ogni testo e ogni scelta di interfaccia. Sono l'identità
di Respiro: la trasparenza radicale è ciò che ci rende l'opposto dello
scare-marketing di categoria. Ogni PR che tocca copy o UI va verificata
contro questa lista.

## Mai

1. **Mai rosso o colori d'allarme per il junk.** Il rosso (`Palette.danger`)
   è riservato agli errori reali (rimozione fallita). Cache e log non sono
   emergenze.
2. **Mai urgenza.** Niente "subito!", "ora!", countdown, badge pulsanti.
   Il Mac dell'utente non sta morendo.
3. **Mai chiamare i file "problemi", "minacce" o "rischi"** quando sono
   semplici file rigenerabili. "Guardia" segnala *cose insolite da
   controllare*, non minacce.
4. **Mai preselezionare elementi a bassa confidenza.** I match "solo nome" e
   "fornitore" partono deselezionati. L'utente sceglie, noi proponiamo.
5. **Mai gonfiare i numeri.** Le dimensioni sono sempre spazio allocato
   misurato ora — mai "fino a", mai stime, mai doppi conteggi.
6. **Mai finte attese.** Se una scansione dura 0,3 secondi, dura 0,3 secondi.
   Niente progress bar teatrali.
7. **Mai dark pattern su Ko-fi.** Il sostegno compare in esattamente due
   punti discreti: la finestra Informazioni e una riga gentile (non modale,
   massimo una volta al mese) dopo una pulizia importante:
   *"Respiro è gratuito e lo resterà. Se ti è utile, un caffè fa piacere ☕"*.
   Mai bloccare, mai interrompere, mai condizionare funzioni.

## Sempre

1. **Sempre spiegare.** Ogni categoria ha il suo "Perché questo file?"
   (`Explanations.swift`). Se aggiungi una categoria, scrivi la spiegazione.
2. **Sempre reversibile per default.** Cestino, mai `rm`, tranne dove
   svuotare è il punto (Cestino stesso) — e lì confermare due volte.
3. **Sempre registrare.** Ogni file toccato finisce nel Registro
   (`ActionLogStore`). Se aggiungi un percorso di rimozione, aggiungi l'hook.
4. **Sempre onesti sui limiti.** Dato mancante = "data sconosciuta", cartella
   illeggibile per permessi = "serve Accesso completo al disco", mai "tutto
   pulito" quando non abbiamo potuto guardare.
5. **Sempre linguaggio umano.** I nomi-firma (Respira, Aria, Zavorra…) hanno
   sempre un sottotitolo piano. Se serve un glossario, abbiamo sbagliato.

## Lessico

Vietati (nomi CleanMyMac): "Smart Scan", "Space Lens", "System Junk",
"Pulizia sistema". I nostri: Respira, Aria, Cestino, Zavorra (Ingombranti +
Doppioni), Panorama, Trasloco, Avvio, Tagliando, Guardia, Diario (Statistiche
+ Registro). Futuri: Coinquilini, Scia, Backup iPhone, Officina.
