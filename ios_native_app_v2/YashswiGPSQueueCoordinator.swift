
import Foundation

final class YashswiGPSQueueCoordinator {

    static let shared = YashswiGPSQueueCoordinator()

    // Keep server synchronization disabled until
    // the PHP response contract has been verified.
    private let automaticSyncEnabled = false

    private var isConfigured = false

    private init() {}

    // MARK: - Configure Monitoring

    func configure() {

        guard !isConfigured else {
            return
        }

        isConfigured = true

        YashswiNetworkMonitor.shared.onConnectionChanged = {
            [weak self] connected in

            guard connected else {
                return
            }

            self?.inspectPendingQueue()
            YashswiPunchOutSyncCoordinator.shared
    .networkDidBecomeAvailable()
        }

        YashswiNetworkMonitor.shared.startMonitoring()
    }

    // MARK: - Read Pending Queue

    func inspectPendingQueue() {

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.inspectPendingQueue()
            }
            return
        }

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {
            return
        }

        guard YashswiNetworkMonitor.shared
            .isNetworkAvailable else {
            return
        }

        let points =
            YashswiOfflineLocationStore.shared.pendingPoints()

        // Never synchronize records belonging to
        // another authenticated employee.
        let employeePoints = points.filter {
            $0.employeeId == employeeId
        }

        guard !employeePoints.isEmpty else {
            return
        }

        NSLog(
            "YASHSWI: %d pending GPS records for current employee",
            employeePoints.count
        )

        // No HTTP requests or record deletion until
        // server acknowledgment is verified.
        guard automaticSyncEnabled else {
            return
        }

        // Future integration point:
        // Verify the active attendance session.
        // Upload only authenticated employee records.
        // Remove a record only after confirmed acceptance.
    }
}
