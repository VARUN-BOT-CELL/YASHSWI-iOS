import Foundation
import WebKit

struct YashswiAttendanceStatus: Decodable {
    let success: Bool
    let date: String
    let trackingActive: Bool
    let attendanceStatus: String

    enum CodingKeys: String, CodingKey {
        case success
        case date
        case trackingActive = "tracking_active"
        case attendanceStatus = "attendance_status"
    }
}

enum YashswiAttendanceStatusError: Error {
    case invalidResponse
    case unauthenticated
    case serverError
}

// Prevent redirects to login pages or other destinations.
private final class YashswiAttendanceRedirectGuard:
    NSObject, URLSessionTaskDelegate {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

final class YashswiAttendanceStatusApi {

    static let shared = YashswiAttendanceStatusApi()

    private init() {}

    func fetchStatus(
        completion: @escaping (
            Result<YashswiAttendanceStatus, Error>
        ) -> Void
    ) {
        guard let url = URL(
            string: "https://yashswi.in/attendance/api_attendance_status.php"
        ), url.scheme == "https",
           url.host == "yashswi.in" else {
            DispatchQueue.main.async {
                completion(.failure(
                    YashswiAttendanceStatusError.invalidResponse
                ))
            }
            return
        }

        let cookieStore = WKWebsiteDataStore.default()
            .httpCookieStore

        cookieStore.getAllCookies { cookies in

            let validCookies = cookies.filter { cookie in

                let domain = cookie.domain.lowercased()
                let validDomain =
                    domain == "yashswi.in" ||
                    domain == ".yashswi.in"

                let validExpiry = cookie.expiresDate.map {
                    $0 > Date()
                } ?? true

                let path = cookie.path
                let validPath = path == "/" ||
                    url.path == path ||
                    url.path.hasPrefix(
                        path.hasSuffix("/") ? path : path + "/"
                    )

                return validDomain &&
                    validExpiry &&
                    validPath &&
                    cookie.isSecure
            }

            guard !validCookies.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(
                        YashswiAttendanceStatusError.unauthenticated
                    ))
                }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.httpShouldHandleCookies = false
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Accept"
            )

            let headers = HTTPCookie.requestHeaderFields(
                with: validCookies
            )

            if let cookieHeader = headers["Cookie"] {
                request.setValue(
                    cookieHeader,
                    forHTTPHeaderField: "Cookie"
                )
            }

            let configuration =
                URLSessionConfiguration.ephemeral

            configuration.httpShouldSetCookies = false
            configuration.httpCookieStorage = nil
            configuration.httpCookieAcceptPolicy = .never
            configuration.urlCredentialStorage = nil

            let session = URLSession(
                configuration: configuration,
                delegate: YashswiAttendanceRedirectGuard(),
                delegateQueue: nil
            )

            session.dataTask(with: request) {
                data, response, error in

                defer {
                    session.finishTasksAndInvalidate()
                }

                let result: Result<
                    YashswiAttendanceStatus, Error
                >

                if let error = error {
                    result = .failure(error)

                } else if let http = response as? HTTPURLResponse,
                          http.statusCode == 401 ||
                          http.statusCode == 403 ||
                          (300...399).contains(http.statusCode) {

                    result = .failure(
                        YashswiAttendanceStatusError.unauthenticated
                    )

                } else if let http = response as? HTTPURLResponse,
                          http.statusCode == 200,
                          let data = data,
                          let status = try? JSONDecoder().decode(
                            YashswiAttendanceStatus.self,
                            from: data
                          ),
                          status.success,
                          ["NOT_PUNCHED_IN", "PUNCHED_IN", "PUNCHED_OUT"]
                            .contains(status.attendanceStatus),
                          status.trackingActive ==
                            (status.attendanceStatus == "PUNCHED_IN"),
                          status.date.range(
                            of: #"^\d{4}-\d{2}-\d{2}$"#,
                            options: .regularExpression
                          ) != nil {

                    result = .success(status)

                } else {
                    result = .failure(
                        YashswiAttendanceStatusError.invalidResponse
                    )
                }

                DispatchQueue.main.async {
                    completion(result)
                }
            }.resume()
        }
    }
}