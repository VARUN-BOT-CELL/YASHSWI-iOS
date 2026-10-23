
import Foundation

final class YashswiPunchOutSyncCoordinator {

    static let shared = YashswiPunchOutSyncCoordinator()

    // Keep automatic synchronization disabled until
    // backend API responses are verified.
    private(set) var automaticSyncEnabled = false

    private(set) var pendingRequestCount = 0

    private init() {}

    // MARK: - Configuration

    func configure() {
        automaticSyncEnabled = false
        inspectPendingRequests()
    }

    // MARK: - Inspect Pending Requests

    func inspectPendingRequests() {

        let requests =
            YashswiOfflinePunchOutStore.shared.pendingRequests()

        pendingRequestCount = requests.count

        #if DEBUG
        print(
            "[YASHSWI] Pending offline Punch Out requests:",
            pendingRequestCount
        )
        #endif

        // Read-only inspection.
        // No server requests or deletion.
    }

    // MARK: - Network Restored

    func networkDidBecomeAvailable() {

        // Inspect saved requests after connectivity returns.
        // Do NOT submit attendance automatically.
        inspectPendingRequests()
    }
}
