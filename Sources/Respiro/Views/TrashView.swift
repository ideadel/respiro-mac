import SwiftUI

struct TrashView: View {
    @ObservedObject var viewModel: TrashViewModel
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "trash.fill")
                .font(.system(size: 44))
                .foregroundStyle(Palette.accent)
            if let size = viewModel.sizeBytes {
                Text(formatBytes(size))
                    .font(.largeTitle.bold()).monospacedDigit()
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText())
                Text("\(viewModel.itemCount) elementi nel Cestino")
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ProgressView("Calcolo dimensione…")
            }
            Button("Svuota il Cestino…", role: .destructive) { showConfirm = true }
                .disabled(viewModel.isWorking || viewModel.itemCount == 0)
            if viewModel.isWorking { ProgressView() }
            if let message = viewModel.message {
                Text(message).font(.callout).foregroundStyle(Palette.textSecondary)
            }
            Label("Lo svuotamento è definitivo e non recuperabile.", systemImage: "exclamationmark.triangle")
                .font(.system(size: 11)).foregroundStyle(Palette.warning)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.windowPadding)
        .task { await viewModel.refresh() }
        .confirmationDialog(
            "Eliminare definitivamente \(viewModel.itemCount) elementi? L'operazione non è recuperabile.",
            isPresented: $showConfirm, titleVisibility: .visible
        ) {
            Button("Svuota il Cestino", role: .destructive) {
                Task { await viewModel.empty() }
            }
        }
    }
}
