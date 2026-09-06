import Foundation

/// "Perché questo file?" — human explanations for every category Respiro can
/// touch. Static Italian copy, honest tone: what the file is, what happens
/// if it goes, when to keep it. No jargon, no fear.
enum Explanations {
    /// Keyed on the `CleanableItem.group` strings the scanners emit.
    static func explanation(forJunkGroup group: String) -> String? {
        switch group {
        case "Cache utente":
            return "Le app ricreano le cache da sole. Cancellarle libera spazio subito; al massimo il primo avvio sarà un filo più lento."
        case "Log utente":
            return "Diari tecnici che le app scrivono per gli sviluppatori. Servono solo per diagnosticare problemi: se il Mac funziona, puoi liberartene."
        case "Stato applicazioni salvato":
            return "La \"fotografia\" delle finestre aperte all'ultima chiusura. Rimuovendola, le app ripartiranno pulite invece di riaprire le finestre di prima."
        case "Junk di Xcode":
            return "File temporanei di compilazione (DerivedData, DeviceSupport, cache Simulator). Xcode li rigenera quando servono."
        case "Archivi Xcode":
            return "Build firmati (.xcarchive) che tieni per l'App Store o per debug. Non sono cache: selezionali solo se sei sicuro di non servirtene."
        case "Simulatori iOS":
            return "Dispositivi virtuali di Xcode, con i dati delle app di prova. Partono deselezionati: toccali solo se vuoi ripartire da zero."
        case "Allegati Mail":
            return "Copie locali degli allegati già scaricati. Le mail originali restano sul server: riaprendo l'allegato, Mail lo riscarica. Partono deselezionati."
        case "Report di crash":
            return "Rapporti .ips/.crash che macOS tiene per gli sviluppatori. Se il Mac funziona, puoi liberartene."
        case "Residui orfani":
            return "Cartelle con il bundle id di un'app che non risulta più installata. Partono deselezionate: controlla prima, potrebbero essere dati che vuoi tenere."
        default:
            return nil
        }
    }
}

extension LeftoverCategory {
    /// Shown next to each leftover group in Trasloco.
    var explanation: String {
        switch self {
        case .preferences, .systemPreferences:
            return "Le impostazioni dell'app. Pesano pochissimo: se pensi di reinstallarla, puoi anche tenerle."
        case .caches, .systemCaches:
            return "File temporanei che l'app ricreava a ogni uso. Senza l'app non servono più a niente."
        case .appSupport, .systemAppSupport:
            return "I dati di lavoro dell'app: documenti interni, database, modelli. Se non reinstallerai l'app, sono solo spazio occupato."
        case .logs, .systemLogs:
            return "Diari tecnici scritti dall'app. Utili solo per diagnosticare problemi dell'app stessa."
        case .savedState:
            return "La fotografia delle finestre aperte all'ultima chiusura dell'app."
        case .containers:
            return "La \"stanza\" isolata dove macOS teneva i dati dell'app (sandbox). Senza l'app resta vuota e inutile."
        case .groupContainers:
            return "Dati condivisi tra l'app e le sue estensioni o altre app dello stesso produttore. Se hai ancora un'altra app dello stesso fornitore, questa voce parte deselezionata."
        case .launchAgentsUser, .launchAgentsSystem:
            return "Un processo che partiva da solo al login per conto dell'app. Senza l'app non serve più."
        case .launchDaemons:
            return "Un processo che partiva da solo all'avvio del Mac per conto dell'app. Senza l'app non serve più."
        case .httpStorages:
            return "Dati di navigazione interna dell'app (richieste web, sessioni)."
        case .webkit:
            return "Cache del motore web usato dall'app per mostrare contenuti online."
        case .cookies:
            return "Cookie salvati dall'app per le sue funzioni online."
        case .applicationScripts:
            return "Script che l'app usava per automatizzare operazioni."
        case .crashReports:
            return "Rapporti generati quando l'app è andata in crash. Servivano agli sviluppatori dell'app."
        case .services:
            return "Voci che l'app aggiungeva al menu Servizi del Finder."
        case .internetPlugins:
            return "Plug-in per il browser installati dall'app. Tecnologia ormai superata: quasi nessun browser li usa più."
        case .audioPlugins:
            return "Componenti audio (AU/VST) installati dall'app. Se usi altre app musicali che li caricano, valuta di tenerli."
        case .quickLook:
            return "Estensione per l'anteprima rapida (barra spaziatrice) dei file dell'app."
        case .prefPanes:
            return "Un pannello che l'app aggiungeva alle Impostazioni di Sistema."
        case .privilegedHelpers:
            return "Un componente con privilegi elevati che l'app usava per operazioni di sistema. Senza l'app è solo un rischio inutile."
        case .pkgReceipts:
            return "La \"ricevuta\" con cui macOS ricorda che l'app era stata installata. Dimenticarla non tocca nessun file: pulisce solo l'archivio installazioni."
        }
    }
}
