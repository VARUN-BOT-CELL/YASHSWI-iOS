
import Foundation
import CoreLocation

// MARK: - Tracking Server Response

struct YashswiTrackingServerResponse {

    let httpStatusCode: Int
    let responseBody: String
    let isConfirmedSaved: Bool

    init(
        httpStatusCode: Int,
        responseBody: String
    ) {
        self.httpStatusCode = httpStatusCode
        self.responseBody = responseBody

        // Confirm GPS storage only when the PHP endpoint
        // explicitly returns {"success":true} with HTTP 2xx.
        guard (200...299).contains(httpStatusCode),
              let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any],
              let saved = json["success"] as? Bool else {
            self.isConfirmedSaved = false
            return
        }

        self.isConfirmedSaved = saved
    }
}

// MARK: - Tracking API

final class YashswiTrackingApi {

    static let shared = YashswiTrackingApi()

    private let endpoint = URL(
        string: "https://yashswi.in/attendance/trackloc/save_track.php"
    )!

    private init() {}

    // MARK: - Errors

    enum TrackingError: LocalizedError {

        case employeeNotAuthenticated
        case trackingNotActive
        case invalidLocation
        case missingSession
        case invalidResponse
        case serverError(Int)

        var errorDescription: String? {

            switch self {

            case .employeeNotAuthenticated:
                return "No authenticated employee ID is available."

            case .trackingNotActive:
                return "Employee GPS tracking is not active."

            case .invalidLocation:
                return "GPS location is inaccurate or outdated."

            case .missingSession:
                return "No YASHSWI website session cookie is available."

            case .invalidResponse:
                return "Unable to verify whether the GPS server saved the location."

            case .serverError(let code):
                return "GPS server returned HTTP \(code)."
            }
        }
    }

    // MARK: - Send GPS Location

    func sendLocation(
        _ location: CLLocation,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {

            complete(
                .failure(TrackingError.employeeNotAuthenticated),
                completion
            )
            return
        }

        guard YashswiLocationManager.shared.isTracking else {

            complete(
                .failure(TrackingError.trackingNotActive),
                completion
            )
            return
        }

        guard CLLocationCoordinate2DIsValid(
            location.coordinate
        ),
        location.horizontalAccuracy >= 0,
        location.horizontalAccuracy <= 100,
        abs(location.timestamp.timeIntervalSinceNow) <= 30 else {

            complete(
                .failure(TrackingError.invalidLocation),
                completion
            )
            return
        }

        // MARK: - Session Cookies

        let cookies = (
            HTTPCookieStorage.shared.cookies(
                for: endpoint
            ) ?? []
        ).filter { cookie in

            let domain = cookie.domain
                .lowercased()
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: ".")
                )

            return domain == "yashswi.in" ||
                domain.hasSuffix(".yashswi.in")
        }

        guard !cookies.isEmpty else {

            complete(
                .failure(TrackingError.missingSession),
                completion
            )
            return
        }

        // MARK: - Prepare Request

        var request = URLRequest(url: endpoint)

        request.httpMethod = "POST"
        request.timeoutInterval = 20

        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        var components = URLComponents()

        components.queryItems = [
            URLQueryItem(
                name: "emp_id",
                value: employeeId
            ),
            URLQueryItem(
                name: "lat",
                value: String(location.coordinate.latitude)
            ),
            URLQueryItem(
                name: "lng",
                value: String(location.coordinate.longitude)
            )
        ]

        let encodedBody = (
            components.percentEncodedQuery ?? ""
        ).replacingOccurrences(
            of: "%20",
            with: "+"
        )

        request.httpBody = encodedBody.data(
            using: .utf8
        )

        let cookieHeaders = HTTPCookie.requestHeaderFields(
            with: cookies
        )

        for (key, value) in cookieHeaders {
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }

        // MARK: - Network Request

        URLSession.shared.dataTask(
            with: request
        ) { [weak self] data, response, error in

            guard let self = self else {
                return
            }

            if let error = error {

                self.complete(
                    .failure(error),
                    completion
                )
                return
            }

            guard let httpResponse =
                response as? HTTPURLResponse else {

                self.complete(
                    .failure(TrackingError.invalidResponse),
                    completion
                )
                return
            }

            guard (200...299).contains(
                httpResponse.statusCode
            ) else {

                self.complete(
                    .failure(
                        TrackingError.serverError(
                            httpResponse.statusCode
                        )
                    ),
                    completion
                )
                return
            }

            // Inspect the server's actual response.
            let inspection = self.inspectServerResponse(
                data: data,
                httpStatusCode: httpResponse.statusCode
            )

            // Until the PHP response contract is known,
            // do not report verified storage success.
            guard inspection.isConfirmedSaved else {

                self.complete(
                    .failure(TrackingError.invalidResponse),
                    completion
                )
                return
            }

            self.complete(
                .success(()),
                completion
            )

        }.resume()
    }

    // MARK: - Server Response Inspection

    func inspectServerResponse(
        data: Data?,
        httpStatusCode: Int
    ) -> YashswiTrackingServerResponse {

        let responseBody: String

        if let data = data {
            responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "[Non-UTF8 response]"
        } else {
            responseBody = ""
        }

        return YashswiTrackingServerResponse(
            httpStatusCode: httpStatusCode,
            responseBody: responseBody
        )
    }

    // MARK: - Completion

    private func complete(
        _ result: Result<Void, Error>,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {

        DispatchQueue.main.async {
            completion(result)
        }
    }
}
