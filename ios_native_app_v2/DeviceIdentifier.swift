
import Foundation

final class DeviceIdentifier {

    static let shared = DeviceIdentifier()

    private let storageKey = "yashswi.ios.device.identifier"

    private init() {}

    var value: String {
        if let data = KeychainHelper.shared.read(forKey: storageKey),
           let identifier = String(data: data, encoding: .utf8),
           !identifier.isEmpty {
            return identifier
        }

        let identifier = UUID().uuidString

        guard let data = identifier.data(using: .utf8),
              KeychainHelper.shared.save(data, forKey: storageKey) else {
            // Don't silently use a new ID for a login if
            // persistent storage is unavailable.
            return ""
        }

        return identifier
    }
}
