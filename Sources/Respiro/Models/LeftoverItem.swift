import Foundation

enum LeftoverCategory: String, CaseIterable, Identifiable {
    case preferences, caches, appSupport, logs, savedState, containers,
         groupContainers, launchAgentsUser, httpStorages, webkit, cookies,
         applicationScripts, crashReports, services, internetPlugins,
         audioPlugins, quickLook, prefPanes,
         launchAgentsSystem, launchDaemons, systemAppSupport, systemPreferences,
         privilegedHelpers, systemCaches, systemLogs, pkgReceipts

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
        case .applicationScripts: return "Script applicazione"
        case .crashReports: return "Report di crash"
        case .services: return "Servizi"
        case .internetPlugins: return "Plug-in Internet"
        case .audioPlugins: return "Plug-in audio"
        case .quickLook: return "QuickLook"
        case .prefPanes: return "Pannelli preferenze"
        case .launchAgentsSystem: return "LaunchAgents (sistema)"
        case .launchDaemons: return "LaunchDaemons"
        case .systemAppSupport: return "Application Support (sistema)"
        case .systemPreferences: return "Preferenze (sistema)"
        case .privilegedHelpers: return "Helper privilegiati"
        case .systemCaches: return "Cache (sistema)"
        case .systemLogs: return "Log (sistema)"
        case .pkgReceipts: return "Ricevute pacchetti (pkg)"
        }
    }

    var sortOrder: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

enum MatchReason: Equatable {
    case bundleIdExact
    case bundleIdPrefix
    case nameMatch
    case plistLabelMatch
    case helperBundleId
    case vendorMatch

    var isHighConfidence: Bool {
        switch self {
        case .bundleIdExact, .bundleIdPrefix, .plistLabelMatch, .helperBundleId: return true
        case .nameMatch, .vendorMatch: return false
        }
    }

    /// COPY-GUARDRAILS: match deboli (solo nome / fornitore) partono deselezionati.
    var shouldSelectByDefault: Bool { isHighConfidence }

    var badge: String {
        switch self {
        case .bundleIdExact: return "bundle id"
        case .bundleIdPrefix: return "bundle id"
        case .plistLabelMatch: return "label"
        case .nameMatch: return "solo nome"
        case .helperBundleId: return "helper"
        case .vendorMatch: return "fornitore"
        }
    }
}

/// A receipt is "removed" via `pkgutil --forget`, not by trashing a file.
enum LeftoverKind: Equatable {
    case file
    case packageReceipt(String)
}

/// Which launchd domain a job must be booted out of before its files go away.
enum LaunchdDomain: Equatable {
    case userGui
    case system
}

struct LeftoverItem: Identifiable {
    let id = UUID()
    let url: URL
    let category: LeftoverCategory
    var sizeBytes: Int64?
    var isSelected: Bool = true
    let requiresElevation: Bool
    let matchReason: MatchReason
    var kind: LeftoverKind = .file
    var launchdLabel: String?
    var launchdDomain: LaunchdDomain?
}
