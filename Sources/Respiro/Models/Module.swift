import Foundation

/// The routing atom. Names use Respiro's own lexicon: signature modules get
/// the breath/home metaphor, utility modules keep plain OS vocabulary
/// (Cestino, Avvio) — never CleanMyMac's names.
enum Module: String, CaseIterable, Identifiable, Hashable {
    case respira, aria, cestino, zavorra, panorama, trasloco,
         avvio, tagliando, guardia, diario

    var id: String { rawValue }

    var title: String {
        switch self {
        case .respira: return "Respira"
        case .aria: return "Aria"
        case .cestino: return "Cestino"
        case .zavorra: return "Zavorra"
        case .panorama: return "Panorama"
        case .trasloco: return "Trasloco"
        case .avvio: return "Avvio"
        case .tagliando: return "Tagliando"
        case .guardia: return "Guardia"
        case .diario: return "Diario"
        }
    }

    /// Plain-language subtitle so the lexicon never becomes cryptic.
    var subtitle: String {
        switch self {
        case .respira: return "Come sta il tuo Mac"
        case .aria: return "Cache e file rigenerabili"
        case .cestino: return "Svuota quando vuoi"
        case .zavorra: return "File grandi e duplicati"
        case .panorama: return "Mappa dello spazio su disco"
        case .trasloco: return "Disinstallazione profonda"
        case .avvio: return "Elementi di login"
        case .tagliando: return "Manutenzione periodica"
        case .guardia: return "Controlli di sicurezza"
        case .diario: return "Statistiche e registro"
        }
    }

    var icon: String {
        switch self {
        case .respira: return "lungs"
        case .aria: return "wind"
        case .cestino: return "trash"
        case .zavorra: return "scalemass"
        case .panorama: return "binoculars"
        case .trasloco: return "shippingbox"
        case .avvio: return "power"
        case .tagliando: return "wrench.and.screwdriver"
        case .guardia: return "checkmark.shield"
        case .diario: return "book.closed"
        }
    }

    /// Filled variant used when the row is selected.
    var selectedIcon: String {
        switch self {
        case .respira: return "lungs.fill"
        case .cestino: return "trash.fill"
        case .zavorra: return "scalemass.fill"
        case .panorama: return "binoculars.fill"
        case .trasloco: return "shippingbox.fill"
        case .guardia: return "checkmark.shield.fill"
        case .diario: return "book.closed.fill"
        default: return icon
        }
    }

    var area: Area {
        switch self {
        case .respira: return .respira
        case .aria, .cestino, .zavorra, .panorama: return .spazio
        case .trasloco: return .app
        case .avvio, .tagliando, .guardia: return .energia
        case .diario: return .diario
        }
    }
}

/// Sidebar level: 5 broad areas instead of a module launcher.
enum Area: String, CaseIterable, Identifiable, Hashable {
    case respira, spazio, app, energia, diario

    var id: String { rawValue }

    var title: String {
        switch self {
        case .respira: return "Respira"
        case .spazio: return "Spazio"
        case .app: return "App"
        case .energia: return "Energia"
        case .diario: return "Diario"
        }
    }

    var subtitle: String {
        switch self {
        case .respira: return "Come sta il tuo Mac"
        case .spazio: return "Libera i giga"
        case .app: return "Trasloco e disinstallazione"
        case .energia: return "Avvio, tagliando, guardia"
        case .diario: return "Cosa ho fatto, file per file"
        }
    }

    var icon: String {
        switch self {
        case .respira: return "lungs"
        case .spazio: return "internaldrive"
        case .app: return "shippingbox"
        case .energia: return "bolt"
        case .diario: return "book.closed"
        }
    }

    var selectedIcon: String {
        switch self {
        case .respira: return "lungs.fill"
        case .spazio: return "internaldrive.fill"
        case .app: return "shippingbox.fill"
        case .energia: return "bolt.fill"
        case .diario: return "book.closed.fill"
        }
    }

    var modules: [Module] {
        Module.allCases.filter { $0.area == self }
    }
}

/// Shared navigation state: sidebar picks the Area, the chip bar inside each
/// area picks the Module. Deep links (home CTA, menu bar) go through here.
@MainActor
final class AppRoute: ObservableObject {
    @Published var area: Area = .respira
    @Published var module: Module = .respira

    func open(_ module: Module) {
        area = module.area
        self.module = module
    }

    /// Keeps the chip selection consistent when the sidebar changes area.
    func selectArea(_ newArea: Area) {
        area = newArea
        if module.area != newArea {
            module = newArea.modules.first ?? .respira
        }
    }
}
