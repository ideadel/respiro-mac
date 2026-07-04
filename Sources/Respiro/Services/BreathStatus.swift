import Foundation

/// Honest narrative state for the home: computed from measured numbers only
/// (free-space %, recoverable estimate from the last scan, days since the
/// last cleaning) — never inflated, never alarmist.
struct BreathStatus {
    enum Level {
        case bene, viziata, corto
    }

    let level: Level
    let headline: String
    let detail: String

    static func compute(freeBytes: Int64?, totalBytes: Int64?,
                        recoverableBytes: Int64?, lastCleaning: Date?) -> BreathStatus {
        let freeRatio: Double? = {
            guard let freeBytes, let totalBytes, totalBytes > 0 else { return nil }
            return Double(freeBytes) / Double(totalBytes)
        }()

        let freeText = freeBytes.map { formatBytes($0) + " liberi" }
        let lastText: String? = lastCleaning.map { date in
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            switch days {
            case 0: return "ultima pulizia oggi"
            case 1: return "ultima pulizia ieri"
            default: return "ultima pulizia \(days) giorni fa"
            }
        }
        let detailParts = [freeText, lastText].compactMap { $0 }
        let detail = detailParts.joined(separator: " · ")

        if let freeRatio, freeRatio < 0.10 {
            return BreathStatus(
                level: .corto,
                headline: "Il tuo Mac ha il fiato corto: meno del 10% di spazio libero.",
                detail: detail.isEmpty ? "Facciamo spazio insieme." : detail
            )
        }
        if let recoverableBytes, recoverableBytes > 5_000_000_000 {
            return BreathStatus(
                level: .corto,
                headline: "Il tuo Mac ha il fiato corto: ci sono \(formatBytes(recoverableBytes)) recuperabili.",
                detail: detail
            )
        }
        if let recoverableBytes, recoverableBytes > 1_000_000_000 {
            return BreathStatus(
                level: .viziata,
                headline: "C'è un po' d'aria viziata: \(formatBytes(recoverableBytes)) di file che le app possono ricreare da sole.",
                detail: detail
            )
        }
        return BreathStatus(
            level: .bene,
            headline: "Il tuo Mac respira bene.",
            detail: detail.isEmpty ? "Tutto in ordine." : detail
        )
    }
}
