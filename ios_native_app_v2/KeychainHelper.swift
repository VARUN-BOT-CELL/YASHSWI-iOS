
import Foundation
import Security

final class KeychainHelper {

    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Save or Update

    func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // First update the existing item without deleting it.
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

        // Only create an item when it does not already exist.
        guard updateStatus == errSecItemNotFound else {
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

        // Handle the rare case where another operation
        // created the same item before this add completed.
        if addStatus == errSecDuplicateItem {
            return SecItemUpdate(
                query as CFDictionary,
                updateAttributes as CFDictionary
            ) == errSecSuccess
        }

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

    // MARK: - Read With Error Information

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
            return .failure(.securityError(status))
        }

        guard let data = result as? Data else {
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

        return status == errSecSuccess ||
            status == errSecItemNotFound
    }
}
