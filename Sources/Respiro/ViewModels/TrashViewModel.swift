import Foundation

@MainActor
final class TrashViewModel: ObservableObject {
    @Published var sizeBytes: Int64?
    @Published var itemCount = 0
    @Published var isWorking = false
    @Published var message: String?

    private var trashURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash", isDirectory: true)
    }

    func refresh() async {
        sizeBytes = nil
        let url = trashURL
        itemCount = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: []))?.count ?? 0
        sizeBytes = await Task.detached { SizeCalculator.recursiveSize(of: url) }.value
    }

    /// Permanently deletes the Trash contents (that is the whole point of
    /// emptying it) — always behind an explicit confirmation in the UI.
    func empty() async {
        isWorking = true
        message = nil
        let url = trashURL
        let failures: Int = await Task.detached {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil, options: []
            ) else { return 0 }
            var failed = 0
            for child in children {
                do { try FileManager.default.removeItem(at: child) } catch { failed += 1 }
            }
            return failed
        }.value
        message = failures == 0 ? "Cestino svuotato." : "\(failures) elementi non eliminabili (in uso o protetti)."
        isWorking = false
        await refresh()
    }
}
