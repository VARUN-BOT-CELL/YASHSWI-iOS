
import Foundation
import Security

struct YashswiPendingPunchOut: Codable, Identifiable {
    let id: UUID
    let employeeId: String
    let deviceId: String
    let requestedAt: Date
    let reason: String
}

final class YashswiOfflinePunchOutStore {

    static let shared = YashswiOfflinePunchOutStore()

    private let service = "in.yashswi.ios.offline-punchout"
    private let account = "pending-punchout-requests"
    private let lock = NSLock()

    private init() {}

    // Save a request locally, without submitting attendance.
    @discardableResult
    func savePendingPunchOut(
        employeeId: String,
        deviceId: String
    ) -> Bool {

        guard !employeeId.isEmpty,
              !deviceId.isEmpty else {
            return false
        }

        lock.lock()
        defer { lock.unlock() }

        var records = readRecords()

        // Avoid duplicate pending requests for one employee.
        if records.contains(where: {
            $0.employeeId == employeeId
        }) {
            return true
        }

        let request = YashswiPendingPunchOut(
            id: UUID(),
            employeeId: employeeId,
            deviceId: deviceId,
            requestedAt: Date(),
            reason: "Location Turned Off"
        )

        records.append(request)
        return writeRecords(records)
    }

    func pendingRequests() -> [YashswiPendingPunchOut] {
        lock.lock()
        defer { lock.unlock() }
        return readRecords()
    }

    func pendingRequests(
        employeeId: String
    ) -> [YashswiPendingPunchOut] {
        return pendingRequests().filter {
            $0.employeeId == employeeId
        }
    }

    // Intentionally no automatic deletion or upload method.
    // Requests require verified server reconciliation.

    private func readRecords() -> [YashswiPendingPunchOut] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let records = try? JSONDecoder().decode(
                [YashswiPendingPunchOut].self,
                from: data
              ) else {
            return []
        }

        return records
    }

    private func writeRecords(
        _ records: [YashswiPendingPunchOut]
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(records) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            update as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        return SecItemAdd(
            attributes as CFDictionary,
            nil
        ) == errSecSuccess
    }
}
