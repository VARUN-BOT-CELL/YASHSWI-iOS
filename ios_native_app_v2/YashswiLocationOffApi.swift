
import Foundation
import CoreLocation

final class YashswiLocationOffApi {

    static let shared = YashswiLocationOffApi()

    private let endpoint = URL(
        string: "https://yashswi.in/attendance/trackloc/log_location_off.php"
    )!

    private init() {}

    enum LocationOffError: LocalizedError {
        case missingEmployee
        case missingSession
        case invalidLocation
        case invalidResponse
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .missingEmployee:
                return "Authenticated employee ID is unavailable."
            case .missingSession:
                return "YASHSWI session cookie is unavailable."
            case .invalidLocation:
                return "No valid previous GPS coordinates are available."
            case .invalidResponse:
                return "Invalid server response."
            case .httpError(let code):
                return "Location-off request failed with HTTP \(code)."
            }
        }
    }

    func prepareLocationOffReport(
        lastLocation: CLLocation?,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {

            completion(.failure(
                LocationOffError.missingEmployee
            ))
            return
        }

        guard let location = lastLocation,
              CLLocationCoordinate2DIsValid(location.coordinate),
              location.horizontalAccuracy >= 0 else {

            completion(.failure(
                LocationOffError.invalidLocation
            ))
            return
        }

        let cookies = (
            HTTPCookieStorage.shared.cookies(for: endpoint) ?? []
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
            completion(.failure(
                LocationOffError.missingSession
            ))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "emp_id", value: employeeId),
            URLQueryItem(
                name: "lat",
                value: String(location.coordinate.latitude)
            ),
            URLQueryItem(
                name: "lng",
                value: String(location.coordinate.longitude)
            )
        ]

        request.httpBody = (
            components.percentEncodedQuery ?? ""
        )
        .replacingOccurrences(of: "%20", with: "+")
        .data(using: .utf8)

        let cookieHeaders = HTTPCookie.requestHeaderFields(
            with: cookies
        )

        for (key, value) in cookieHeaders {
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }

        completion(.success(request))
    }
}
