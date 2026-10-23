
import Foundation

final class DeviceIdentifier {

    static let shared = DeviceIdentifier()

    private let storageKey =
        "yashswi.ios.device.identifier"

    private init() {}

    var value: String {

        switch KeychainHelper.shared.readWithStatus(
            forKey: storageKey
        ) {

        case .success(let data):

            guard let identifier = String(
                data: data,
                encoding: .utf8
            ), !identifier.isEmpty else {

                NSLog(
                    "[YASHSWI Device] Stored identifier is invalid"
                )

                return ""
            }

            return identifier

        case .failure(.itemNotFound):

            // Only generate a new identifier when
            // Keychain confirms that none exists.
            let identifier = UUID().uuidString
            let data = Data(identifier.utf8)

            guard KeychainHelper.shared.save(
                data,
                forKey: storageKey
            ) else {
                NSLog(
                    "[YASHSWI Device] Identifier persistence failed"
                )
                return ""
            }

            // Verify the exact saved value can be read.
            switch KeychainHelper.shared.readWithStatus(
                forKey: storageKey
            ) {
            case .success(let storedData):
                guard storedData == data else {
                    NSLog(
                        "[YASHSWI Device] Saved identifier verification failed"
                    )
                    return ""
                }

                return identifier

            case .failure:
                NSLog(
                    "[YASHSWI Device] Saved identifier could not be verified"
                )
                return ""
            }

        case .failure(.unexpectedData):
            NSLog(
                "[YASHSWI Device] Invalid Keychain response"
            )
            return ""

        case .failure(.securityError(let status)):
            NSLog(
                "[YASHSWI Device] Keychain unavailable: %d",
                Int(status)
            )
            return ""
        }
    }
}
