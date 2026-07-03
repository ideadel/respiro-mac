import SwiftUI

struct SmartScanView: View {
    @ObservedObject var junk: CleanupListViewModel
    @ObservedObject var trash: TrashViewModel
    @ObservedObject var protection: CleanupListViewModel
    @ObservedObject var startup: StartupViewModel
    @Binding var selection: Module?

    @State private var isScanning = false
    @State private var hasScanned = false

    private var freeable: Int64 { junk.totalSize + (trash.sizeBytes ?? 0) }

    var body: some View {
        VStack {
            if hasScanned && !isScanning {
                resultsState
            } else {
                idleState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.windowPadding)
        .navigationTitle("Smart Scan")
    }

    // MARK: Direction A — mascot hero (idle / scanning)

    private var idleState: some View {
        VStack(spacing: 22) {
            Spacer()
            MelaMascot(size: 132, state: isScanning ? .scanning : .idle)
            VStack(spacing: 8) {
                Text("Dai al tuo Mac un po' di respiro")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Palette.textPrimary)
                Text("Junk di sistema, Cestino, elementi di avvio e controlli di sicurezza — rivisti in un solo passaggio. Tutto resta sul tuo Mac.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            if isScanning {
                ProgressView().controlSize(.large)
            } else {
                Button("Analizza") { Task { await runScan() } }
                    .buttonStyle(.primaryCTA)
                    .keyboardShortcut(.defaultAction)
            }
            Text("Niente viene rimosso senza la tua conferma · 100% offline")
                .font(.system(size: 11))
                .foregroundStyle(Palette.textSecondary)
            Spacer()
        }
    }

    // MARK: Direction B — results, mascot speaks

    private var resultsState: some View {
        VStack(spacing: 18) {
            HStack(spacing: 16) {
                MelaMascot(size: 64, state: .happy)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Tutto pronto! Ho trovato")
                        Text(formatBytes(freeable))
                            .foregroundStyle(Palette.accent)
                            .contentTransition(.numericText())
                        Text("liberabili.")
                    }
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    Text("\(junk.items.count + protection.items.count) elementi analizzati · "
                         + (protection.items.isEmpty ? "nessuna anomalia" : "\(protection.items.count) da controllare"))
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glassCard()
                Spacer()
                Button("Rivedi e pulisci") { selection = .systemJunk }
                    .buttonStyle(.primaryCTA)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                card(.systemJunk, "Pulizia sistema", formatBytes(junk.totalSize),
                     "\(junk.items.count) elementi eliminabili")
                card(.trash, "Cestino", trash.sizeBytes.map(formatBytes) ?? "—",
                     "\(trash.itemCount) elementi")
                card(.startup, "Avvio", "\(startup.items.count)",
                     "elementi di terze parti")
                card(.protection, "Protezione", protection.items.isEmpty ? "OK" : "\(protection.items.count)",
                     protection.items.isEmpty ? "nessuna anomalia" : "anomalie da rivedere",
                     tint: protection.items.isEmpty ? Palette.success : Palette.warning)
            }

            Spacer()
            Button("Analizza di nuovo") { Task { await runScan() } }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accent)
        }
    }

    private func card(_ module: Module, _ title: String, _ value: String, _ subtitle: String,
                      tint: Color = Palette.accent) -> some View {
        Button {
            selection = module
        } label: {
            HStack(spacing: 14) {
                Image(systemName: module.icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.textPrimary)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.textSecondary).font(.caption)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private func runScan() async {
        isScanning = true
        async let a: () = junk.scan()
        async let b: () = trash.refresh()
        async let c: () = protection.scan()
        async let d: () = startup.refresh()
        _ = await (a, b, c, d)
        isScanning = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { hasScanned = true }
    }
}
