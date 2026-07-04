import Foundation
import Sparkle

/// Sparkle auto-update wiring. The updater only starts when the app runs
/// from a real bundle with a valid EdDSA public key in Info.plist — the
/// CLI/self-test binary and un-keyed dev builds skip it entirely.
@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()

    private let controller: SPUStandardUpdaterController
    let isActive: Bool

    private init() {
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        let hasValidKey = (publicKey?.count ?? 0) >= 40 && publicKey?.contains("REPLACE") == false
        isActive = Bundle.main.bundleIdentifier != nil && hasValidKey
        controller = SPUStandardUpdaterController(startingUpdater: isActive,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
