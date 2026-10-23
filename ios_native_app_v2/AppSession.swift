
import Foundation

final class AppSession {

    static let shared = AppSession()

    private(set) var currentUser: User?
    private(set) var authenticatedEmployeeId: String?

    private let userStorageKey = "yashswi.employee.profile"

    private init() {}

    var isAuthenticated: Bool {
        currentUser != nil || authenticatedEmployeeId != nil
    }

    func signIn(_ user: User) {
        currentUser = user
        authenticatedEmployeeId = user.empId

        // Store employee profile securely.
        // This is not proof of a valid server session.
        if let data = try? JSONEncoder().encode(user) {
            let saved = KeychainHelper.shared.save(
                data,
                forKey: userStorageKey
            )

            if !saved {
                print("Unable to securely save employee profile.")
            }
        }
    }

    func setAuthenticatedEmployeeId(_ empId: String) {
        let value = empId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        authenticatedEmployeeId = value.isEmpty ? nil : value
    }

    func signOut() {
        currentUser = nil
        authenticatedEmployeeId = nil

        _ = KeychainHelper.shared.delete(
            forKey: userStorageKey
        )
    }

    func savedEmployeeProfile() -> User? {
        guard let data = KeychainHelper.shared.read(
            forKey: userStorageKey
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(
            User.self,
            from: data
        )
    }
}
