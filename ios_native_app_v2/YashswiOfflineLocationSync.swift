
import Foundation

final class YashswiOfflineLocationSync {

    static let shared = YashswiOfflineLocationSync()

    private init() {}

    struct SyncStatus {
        let pendingCount: Int
        let currentEmployeeCount: Int
        let isReadyForUpload: Bool
        let message: String
    }

    // Read-only safety check.
    // Does not upload or delete any GPS records.
    func checkPendingLocations() -> SyncStatus {

        let readResult = YashswiOfflineLocationStore.shared
            .readPendingPoints()

        let points: [YashswiOfflineLocationPoint]

        switch readResult {
        case .success(let storedPoints):
            points = storedPoints

        case .failure(let error):
            return SyncStatus(
                pendingCount: 0,
                currentEmployeeCount: 0,
                isReadyForUpload: false,
                message: "Unable to read offline GPS records: \(error.localizedDescription). Existing data has not been modified."
            )
        }

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {

            return SyncStatus(
                pendingCount: points.count,
                currentEmployeeCount: 0,
                isReadyForUpload: false,
                message: "No authenticated employee is available."
            )
        }

        let employeePoints = points.filter {
            $0.employeeId == employeeId
        }

        guard !employeePoints.isEmpty else {
            return SyncStatus(
                pendingCount: points.count,
                currentEmployeeCount: 0,
                isReadyForUpload: false,
                message: "No pending GPS points for this employee."
            )
        }

        let endpoint = URL(
            string: "https://yashswi.in/attendance/trackloc/save_track.php"
        )!

        let cookies = HTTPCookieStorage.shared
            .cookies(for: endpoint) ?? []

        let hasYashswiCookie = cookies.contains { cookie in
            let domain = cookie.domain
                .lowercased()
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: ".")
                )

            return domain == "yashswi.in" ||
                domain.hasSuffix(".yashswi.in")
        }

        return SyncStatus(
            pendingCount: points.count,
            currentEmployeeCount: employeePoints.count,
            isReadyForUpload: false,
            message: hasYashswiCookie
                ? "Offline GPS records found. Server acceptance and authenticated session verification are still required."
                : "Offline GPS records found, but no YASHSWI HTTP session cookie is available."
        )
    }
}
