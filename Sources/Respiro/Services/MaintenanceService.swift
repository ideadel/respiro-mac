import Foundation

struct MaintenanceTask: Identifiable {
    let id: String
    let title: String
    let detail: String
    let needsAdmin: Bool
    let command: String
    var isAvailable: Bool = true
}

final class MaintenanceService {
    static let lsregisterPath =
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    static let tasks: [MaintenanceTask] = [
        MaintenanceTask(id: "dns",
                        title: "Svuota cache DNS",
                        detail: "Risolve problemi di rete dopo cambi di DNS o VPN.",
                        needsAdmin: true,
                        command: "dscacheutil -flushcache; killall -HUP mDNSResponder"),
        MaintenanceTask(id: "purge",
                        title: "Libera RAM",
                        detail: "Svuota la cache disco del kernel (equivalente di 'purge').",
                        needsAdmin: true,
                        command: "purge",
                        isAvailable: FileManager.default.fileExists(atPath: "/usr/sbin/purge")
                            || FileManager.default.fileExists(atPath: "/usr/bin/purge")),
        MaintenanceTask(id: "spotlight",
                        title: "Reindicizza Spotlight",
                        detail: "Cancella e ricostruisce l'indice di ricerca del volume di avvio.",
                        needsAdmin: true,
                        command: "mdutil -E /"),
        MaintenanceTask(id: "launchservices",
                        title: "Ricostruisci database Launch Services",
                        detail: "Ripara le associazioni file-app e le voci duplicate in \"Apri con\".",
                        needsAdmin: false,
                        command: "\(MaintenanceService.lsregisterPath) -kill -r -domain local -domain system -domain user"),
        MaintenanceTask(id: "periodic",
                        title: "Esegui script di manutenzione",
                        detail: "Esegue gli script periodici di sistema (daily, weekly, monthly).",
                        needsAdmin: true,
                        command: "periodic daily weekly monthly",
                        isAvailable: FileManager.default.fileExists(atPath: "/usr/sbin/periodic")),
    ]

    func run(_ task: MaintenanceTask) async throws {
        if task.needsAdmin {
            try await ElevatedCommandRunner().run(task.command)
        } else {
            let (status, _, stderr) = try await ProcessRunner.run("/bin/zsh", ["-c", task.command])
            if status != 0 {
                throw RemovalError(message: stderr.isEmpty ? "Uscita con codice \(status)" : stderr)
            }
        }
    }
}
