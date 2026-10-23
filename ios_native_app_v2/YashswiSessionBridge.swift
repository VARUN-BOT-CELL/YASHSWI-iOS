import Foundation
import WebKit

final class YashswiSessionBridge {

    static let shared = YashswiSessionBridge()

    private init() {}

    func synchronizeCookies(
        completion: @escaping (Bool) -> Void
    ) {
        let cookies = HTTPCookieStorage.shared.cookies ?? []

        let validCookies = cookies.filter { cookie in
            let domain = cookie.domain
                .lowercased()
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: ".")
                )

            let trustedDomain =
                domain == "yashswi.in" ||
                domain.hasSuffix(".yashswi.in")

            let notExpired =
                cookie.expiresDate.map {
                    $0 > Date()
                } ?? true

            return trustedDomain &&
                   notExpired &&
                   cookie.isSecure
        }

        guard !validCookies.isEmpty else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        let cookieStore = WKWebsiteDataStore
            .default()
            .httpCookieStore

        let group = DispatchGroup()

        for cookie in validCookies {
            group.enter()

            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            cookieStore.getAllCookies { storedCookies in

                let copied = validCookies.allSatisfy { expected in
                    storedCookies.contains { actual in
                        actual.name == expected.name &&
                        actual.value == expected.value &&
                        actual.domain == expected.domain &&
                        actual.path == expected.path
                    }
                }

                completion(copied)
            }
        }
    }
}
