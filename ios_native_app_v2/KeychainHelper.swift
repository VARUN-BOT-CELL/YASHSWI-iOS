
import Foundation
import Security

final class KeychainHelper {

    static let shared = KeychainHelper()

    private init() {}

    // Log status codes only. Never log stored values,
    // passwords, device IDs or employee data.
    private func report(
        _ operation: String,
        status: OSStatus
    ) {
        let description =
            SecCopyErrorMessageString(status, nil) as String?
            ?? "Unknown security error"

        NSLog(
            "[YASHSWI Keychain] %@ failed: OSStatus %d (%@)",
            operation,
            Int(status),
            description
        )
    }

    // MARK: - Save or Update

    func save(_ data: Data, forKey key: String) -> Bool {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            updateAttributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            report("Update", status: updateStatus)
            return false
        }

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(
            attributes as CFDictionary,
            nil
        )

        if addStatus == errSecSuccess {
            return true
        }

        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(
                query as CFDictionary,
                updateAttributes as CFDictionary
            )

            if retryStatus == errSecSuccess {
                return true
            }

            report("Retry update", status: retryStatus)
            return false
        }

        report("Add", status: addStatus)
        return false
    }

    // MARK: - Read

    func read(forKey key: String) -> Data? {
        switch readWithStatus(forKey: key) {
        case .success(let data):
            return data

        case .failure:
            return nil
        }
    }

    enum KeychainError: Error {
        case itemNotFound
        case unexpectedData
        case securityError(OSStatus)
    }

    func readWithStatus(
        forKey key: String
    ) -> Result<Data, KeychainError> {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return .failure(.itemNotFound)
        }

        guard status == errSecSuccess else {
            report("Read", status: status)
            return .failure(.securityError(status))
        }

        guard let data = result as? Data else {
            NSLog("[YASHSWI Keychain] Unexpected read data type")
            return .failure(.unexpectedData)
        }

        return .success(data)
    }

    // MARK: - Delete

    func delete(forKey key: String) -> Bool {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess ||
            status == errSecItemNotFound {
            return true
        }

        report("Delete", status: status)
        return false
    }
}
