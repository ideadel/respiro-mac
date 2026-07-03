import Foundation

enum Module: String, CaseIterable, Identifiable, Hashable {
    case smartScan, systemJunk, trash, uninstaller, startup, maintenance,
         largeFiles, duplicates, spaceLens, protection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smartScan: return "Smart Scan"
        case .systemJunk: return "Pulizia sistema"
        case .trash: return "Cestino"
        case .uninstaller: return "Disinstallatore"
        case .startup: return "Avvio"
        case .maintenance: return "Manutenzione"
        case .largeFiles: return "File grandi"
        case .duplicates: return "Duplicati"
        case .spaceLens: return "Space Lens"
        case .protection: return "Protezione"
        }
    }

    var icon: String {
        switch self {
        case .smartScan: return "sparkles"
        case .systemJunk: return "internaldrive"
        case .trash: return "trash"
        case .uninstaller: return "app.dashed"
        case .startup: return "power"
        case .maintenance: return "wrench.and.screwdriver"
        case .largeFiles: return "doc.badge.clock"
        case .duplicates: return "doc.on.doc"
        case .spaceLens: return "rectangle.3.group"
        case .protection: return "checkmark.shield"
        }
    }

    /// Filled variant used when the row is selected.
    var selectedIcon: String {
        switch self {
        case .systemJunk: return "internaldrive.fill"
        case .trash: return "trash.fill"
        case .protection: return "checkmark.shield.fill"
        default: return icon
        }
    }
}

struct ModuleSection: Identifiable {
    let title: String
    let modules: [Module]
    var id: String { title }

    static let all: [ModuleSection] = [
        ModuleSection(title: "Riepilogo", modules: [.smartScan]),
        ModuleSection(title: "Pulizia", modules: [.systemJunk, .trash]),
        ModuleSection(title: "Applicazioni", modules: [.uninstaller]),
        ModuleSection(title: "Velocità", modules: [.startup, .maintenance]),
        ModuleSection(title: "Spazio", modules: [.largeFiles, .duplicates, .spaceLens]),
        ModuleSection(title: "Sicurezza", modules: [.protection]),
    ]
}
