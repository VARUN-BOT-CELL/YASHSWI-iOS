
import Foundation
import Security
import LocalAuthentication

struct YashswiBiometricCredentials: Codable {
    let employeeId: String
    let password: String
}

enum YashswiBiometricCredentialError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Saved biometric login is unavailable. Please sign in with your password."
    }
}

final class YashswiBiometricCredentialStore {

    static let shared = YashswiBiometricCredentialStore()

    private let service = "in.yashswi.ios.biometric-login"
    private let account = "employee-credentials"
    private let enabledKey = "yashswi.ios.biometric.enabled"

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    // Only called after successful server login
    // and explicit employee permission.
    @discardableResult
    func enable(
        employeeId: String,
        password: String
    ) -> Bool {
        guard !employeeId.isEmpty,
              !password.isEmpty else {
            return false
        }

        var error: Unmanaged<CFError>?

        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            return false
        }

        let credentials = YashswiBiometricCredentials(
            employeeId: employeeId,
            password: password
        )

        guard let data = try? JSONEncoder().encode(
            credentials
        ) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Replace previously enrolled credentials.
        let deletionStatus = SecItemDelete(query as CFDictionary)

        guard deletionStatus == errSecSuccess ||
              deletionStatus == errSecItemNotFound else {
            return false
        }

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessControl as String] = access

        let saved = SecItemAdd(
            attributes as CFDictionary,
            nil
        ) == errSecSuccess

        UserDefaults.standard.set(
            saved,
            forKey: enabledKey
        )

        return saved
    }

    func unlock(
        completion: @escaping (
            Result<
                YashswiBiometricCredentials,
                YashswiBiometricCredentialError
            >
        ) -> Void
    ) {
        guard isEnabled else {
            DispatchQueue.main.async {
                completion(.failure(.unavailable))
            }
            return
        }

        let context = LAContext()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
            kSecUseOperationPrompt as String:
                "Use Face ID or Touch ID to sign in to YASHSWI"
        ]

        DispatchQueue.global(qos: .userInitiated).async {
            var result: CFTypeRef?

            let status = SecItemCopyMatching(
                query as CFDictionary,
                &result
            )

            let credentials: YashswiBiometricCredentials?

            if status == errSecSuccess,
               let data = result as? Data {
                credentials = try? JSONDecoder().decode(
                    YashswiBiometricCredentials.self,
                    from: data
                )
            } else {
                credentials = nil
            }

            DispatchQueue.main.async {
                if let credentials = credentials {
                    completion(.success(credentials))
                } else {
                    completion(.failure(.unavailable))
                }
            }
        }
    }

    // Retain compatibility with the old save method.
    @discardableResult
    func save(
        employeeId: String,
        password: String
    ) -> Bool {
        enable(
            employeeId: employeeId,
            password: password
        )
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        UserDefaults.standard.set(
            false,
            forKey: enabledKey
        )
    }
}
