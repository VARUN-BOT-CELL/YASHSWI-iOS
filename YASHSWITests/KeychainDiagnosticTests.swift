import XCTest
import Foundation
import Security
@testable import YASHSWI

final class KeychainDiagnosticTests: XCTestCase {

    func testKeychainStorage() {
        let key = "yashswi.diagnostic." + UUID().uuidString
        let expected = Data("test-only".utf8)

        defer {
            _ = KeychainHelper.shared.delete(forKey: key)
        }

        let saved = KeychainHelper.shared.save(
            expected,
            forKey: key
        )

        XCTAssertTrue(saved, "Keychain save failed")
        guard saved else { return }

        let actual = KeychainHelper.shared.read(forKey: key)
        XCTAssertEqual(actual, expected)

        NSLog("[YASHSWI TEST] Keychain storage PASS")
    }

    func testDeviceIdentifierPersistence() {
        let first = DeviceIdentifier.shared.value
        let second = DeviceIdentifier.shared.value

        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(first, second)

        if !first.isEmpty && first == second {
            NSLog("[YASHSWI TEST] Device identifier PASS")
        }
    }
}