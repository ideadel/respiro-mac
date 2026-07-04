import Foundation
import SwiftUI

@MainActor
final class AppListViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var searchText = ""
    @Published var isScanning = false

    private let scanner = AppScanner()

    var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        let scanned = await scanner.scanInstalledApps()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            apps = scanned
        }
    }

    func removeApp(id: String) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            apps.removeAll { $0.id == id }
        }
    }
}
