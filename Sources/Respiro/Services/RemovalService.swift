import Foundation

struct RemovalResult: Identifiable {
    let id = UUID()
    let url: URL
    let category: LeftoverCategory?
    let success: Bool
    let errorDescription: String?
}

struct RemovalError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum RemovalErrorMessage {
    /// macOS NSError strings are English — translate the common cases for the UI.
    static func humanize(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Rimozione non riuscita." }
        let l = raw.lowercased()
        if isPermissionFailure(raw) {
            return "Questo file è protetto: Respiro chiederà la password di amministratore e riproverà."
        }
        if l.contains("in use") || l.contains("busy") || l.contains("in uso") {
            return "Il file è in uso: chiudi l'app e riprova."
        }
        return raw
    }

    static func isPermissionFailure(_ raw: String?) -> Bool {
        guard let raw, !raw.isEmpty else { return false }
        let l = raw.lowercased()
        return l.contains("permission") || l.contains("permess") || l.contains("not permitted")
            || l.contains("password di amministratore")
    }

    static func humanizeAppBundleFailure() -> String {
        "Non sono riuscito a spostare l'app nel Cestino. Chiudila del tutto (o forza chiusura) e riprova: se compare, inserisci la password di amministratore."
    }

    static func humanizeElevatedFailure(for url: URL, extensionUninstallAttempted: Bool = false) -> String {
        let name = url.lastPathComponent.lowercased()
        if name.hasSuffix(".appex") || name.contains("camera-extension") || name.contains("systemextension") {
            if extensionUninstallAttempted {
                return "Estensione ancora registrata dal sistema. Riavvia il Mac per completare la rimozione, oppure disattivala in Impostazioni di Sistema › Generali › Accessori."
            }
            return "Estensione di sistema ancora attiva. Chiudi l'app, verifica in Impostazioni di Sistema › Generali › Accessori, poi riprova."
        }
        return "Il file non è stato rimosso: potrebbe essere in uso o protetto dal sistema."
    }
}

struct RemovalService {
    /// Moves user-owned items to the Trash (recoverable with "Put Back").
    func moveToTrash(_ items: [LeftoverItem]) async -> [RemovalResult] {
        var results: [RemovalResult] = []
        for item in items {
            guard DenyList.validateForRemoval(item.url) else {
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: false,
                                             errorDescription: "Bloccato dalla lista di sicurezza"))
                continue
            }
            if !FileManager.default.fileExists(atPath: item.url.path) {
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: true, errorDescription: nil))
                continue
            }
            do {
                try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: true, errorDescription: nil))
            } catch {
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: false,
                                             errorDescription: RemovalErrorMessage.humanize(error.localizedDescription)))
            }
        }
        return results
    }

    /// URL-based variant used by the cleanup modules.
    func moveToTrash(urls: [URL]) async -> [RemovalResult] {
        var results: [RemovalResult] = []
        for url in urls {
            guard DenyList.validateForRemoval(url) else {
                results.append(RemovalResult(url: url, category: nil, success: false,
                                             errorDescription: "Bloccato dalla lista di sicurezza"))
                continue
            }
            if !FileManager.default.fileExists(atPath: url.path) {
                results.append(RemovalResult(url: url, category: nil, success: true, errorDescription: nil))
                continue
            }
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                results.append(RemovalResult(url: url, category: nil, success: true, errorDescription: nil))
            } catch {
                results.append(RemovalResult(url: url, category: nil, success: false,
                                             errorDescription: RemovalErrorMessage.humanize(error.localizedDescription)))
            }
        }
        return results
    }

    func moveAppToTrash(_ app: InstalledApp) async throws {
        guard !DenyList.isRunningApp(bundleURL: app.bundleURL, bundleIdentifier: app.bundleIdentifier),
              !DenyList.isBlockedBundleId(app.bundleIdentifier),
              DenyList.validateForRemoval(app.bundleURL) else {
            throw RemovalError(message: "Bloccato dalla lista di sicurezza: \(app.bundleURL.path)")
        }
        try FileManager.default.trashItem(at: app.bundleURL, resultingItemURL: nil)
    }
}
