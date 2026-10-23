
import Foundation
import LocalAuthentication

final class YashswiBiometricManager {

    static let shared = YashswiBiometricManager()

    private init() {}

    var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    var biometricTitle: String {
        let context = LAContext()
        var error: NSError?

        _ = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Login"
        }
    }

    func authenticate(
        reason: String = "Unlock your YASHSWI employee account",
        completion: @escaping (Bool, String?) -> Void
    ) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            DispatchQueue.main.async {
                completion(
                    false,
                    error?.localizedDescription ??
                        "Biometric authentication is unavailable."
                )
            }
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authenticationError in

            DispatchQueue.main.async {
                completion(
                    success,
                    authenticationError?.localizedDescription
                )
            }
        }
    }
}
