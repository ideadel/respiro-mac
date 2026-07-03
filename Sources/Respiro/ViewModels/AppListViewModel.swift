import Foundation

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
        apps = await scanner.scanInstalledApps()
        isScanning = false
    }
}
