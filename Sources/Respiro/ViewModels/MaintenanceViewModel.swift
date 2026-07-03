import Foundation

@MainActor
final class MaintenanceViewModel: ObservableObject {
    enum TaskStatus: Equatable {
        case success
        case failure(String)
    }

    @Published var runningTaskID: String?
    @Published var statuses: [String: TaskStatus] = [:]

    let tasks = MaintenanceService.tasks.filter(\.isAvailable)
    private let service = MaintenanceService()

    func run(_ task: MaintenanceTask) async {
        runningTaskID = task.id
        statuses[task.id] = nil
        do {
            try await service.run(task)
            statuses[task.id] = .success
        } catch {
            statuses[task.id] = .failure(error.localizedDescription)
        }
        runningTaskID = nil
    }
}
