
import Foundation

struct AndroidLoginResponse: Decodable {

    let success: Bool
    let message: String?
    let dashboardURL: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case dashboardURL = "dashboard_url"
    }

    static func parse(_ data: Data) throws -> AndroidLoginResponse {
        try JSONDecoder().decode(
            AndroidLoginResponse.self,
            from: data
        )
    }

    var resolvedDashboardURL: URL? {
        let fallback = "https://yashswi.in/user/manager.php"

        let path = dashboardURL?.isEmpty == false
            ? dashboardURL!
            : fallback

        guard let url = URL(string: path),
              url.scheme == "https",
              url.host?.lowercased() == "yashswi.in" else {
            return nil
        }

        return url
    }
}
