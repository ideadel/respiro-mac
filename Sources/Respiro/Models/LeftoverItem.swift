import Foundation

enum LeftoverCategory: String, CaseIterable, Identifiable {
    case preferences, caches, appSupport, logs, savedState, containers,
         groupContainers, launchAgentsUser, httpStorages, webkit, cookies,
         launchAgentsSystem, launchDaemons, systemAppSupport, systemPreferences

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preferences: return "Preferenze"
        case .caches: return "Cache"
        case .appSupport: return "Application Support"
        case .logs: return "Log"
        case .savedState: return "Stato salvato"
        case .containers: return "Container"
        case .groupContainers: return "Group Container"
        case .launchAgentsUser: return "LaunchAgents (utente)"
        case .httpStorages: return "HTTPStorages"
        case .webkit: return "WebKit"
        case .cookies: return "Cookie"
        case .launchAgentsSystem: return "LaunchAgents (sistema)"
        case .launchDaemons: return "LaunchDaemons"
        case .systemAppSupport: return "Application Support (sistema)"
        case .systemPreferences: return "Preferenze (sistema)"
        }
    }

    var sortOrder: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

enum MatchReason {
    case bundleIdExact
    case bundleIdPrefix
    case nameMatch
    case plistLabelMatch

    var isHighConfidence: Bool {
        switch self {
        case .bundleIdExact, .bundleIdPrefix, .plistLabelMatch: return true
        case .nameMatch: return false
        }
    }

    var badge: String {
        switch self {
        case .bundleIdExact: return "bundle id"
        case .bundleIdPrefix: return "bundle id"
        case .plistLabelMatch: return "label"
        case .nameMatch: return "solo nome"
        }
    }
}

struct LeftoverItem: Identifiable {
    let id = UUID()
    let url: URL
    let category: LeftoverCategory
    var sizeBytes: Int64?
    var isSelected: Bool = true
    let requiresElevation: Bool
    let matchReason: MatchReason
}
