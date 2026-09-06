import Foundation

/// Suggerimento onesto su una voce di Panorama: niente allarmi, solo
/// "si ricrea", "rivedi" o "tieni".
enum SpaceAdvice: Equatable {
    case regenerable
    case review
    case keep

    var label: String {
        switch self {
        case .regenerable: return "Si ricrea"
        case .review: return "Rivedi"
        case .keep: return "Tieni"
        }
    }

    var explanation: String {
        switch self {
        case .regenerable:
            return "Cache, log o file di compilazione: le app li rifanno da sole."
        case .review:
            return "Spesso è spazio che non serve più (download, installer), ma controlla prima."
        case .keep:
            return "Documenti, foto o dati delle app: toccali solo se sai cosa sono."
        }
    }

    static func classify(_ url: URL, isDirectory: Bool) -> SpaceAdvice {
        let name = url.lastPathComponent.lowercased()
        let path = url.standardizedFileURL.path

        if name.contains("photos library") || name.hasSuffix(".photoslibrary") { return .keep }
        if name == "documents" || name == "documenti" || name == "pictures"
            || name == "immagini" || name == "movies" || name == "film"
            || name == "music" || name == "musica" { return .keep }
        if name == "applications" || name == "applicazioni" { return .keep }
        if path.contains("/Library/Mobile Documents") { return .keep }

        if name == "caches" || name == "logs" || name == "deriveddata"
            || name == "saved application state" || name == "coresimulator"
            || name == "node_modules" || name == "__pycache__" {
            return .regenerable
        }
        if path.contains("/Library/Caches") || path.contains("/Library/Logs")
            || path.contains("/Library/Developer/Xcode/DerivedData")
            || path.contains("/Library/Developer/CoreSimulator/Caches") {
            return .regenerable
        }

        if name == "downloads" || name == "download" { return .review }
        if !isDirectory {
            let ext = url.pathExtension.lowercased()
            if ["dmg", "zip", "pkg", "iso", "ipa"].contains(ext) { return .review }
        }
        if name == "library" || name == "libreria" { return .review }

        return .keep
    }
}
