import Foundation

/// Generic selectable item used by the cleanup modules (system junk, large
/// files, duplicates, protection findings). The uninstaller keeps its richer
/// LeftoverItem model.
struct CleanableItem: Identifiable {
    let id = UUID()
    let url: URL
    let group: String
    var detail: String?
    var sizeBytes: Int64?
    var isSelected: Bool = true
    var requiresElevation: Bool = false
}

func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}
