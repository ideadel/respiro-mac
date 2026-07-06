import SwiftUI

struct MaintenanceView: View {
    @ObservedObject var viewModel: MaintenanceViewModel

    var body: some View {
        VStack(spacing: 14) {
            taskList
        }
        .padding(Metrics.windowPadding)
    }

    private var taskList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                    taskRow(task)
                    if index < viewModel.tasks.count - 1 {
                        Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                    }
                }
            }
            .glassCard()
        }
    }

    private func taskRow(_ task: MaintenanceTask) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textPrimary)
                    if task.needsAdmin {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Text(task.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            switch viewModel.statuses[task.id] {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.success)
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Palette.danger)
                    .help(message)
            case nil:
                EmptyView()
            }
            if viewModel.runningTaskID == task.id {
                ProgressView().controlSize(.small)
            } else {
                Button("Esegui") {
                    Task { await viewModel.run(task) }
                }
                .controlSize(.small)
                .disabled(viewModel.runningTaskID != nil)
            }
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
    }
}
