
import Foundation

struct YashswiAppConfiguration {
    let showSplashAd: Bool
    let showRewardAd: Bool
    let showBannerAd: Bool
    let showAd: Bool
    let adImageURL: URL?
    let splashDurationMilliseconds: Int

    static let defaultConfiguration = YashswiAppConfiguration(
        showSplashAd: false,
        showRewardAd: false,
        showBannerAd: false,
        showAd: false,
        adImageURL: nil,
        splashDurationMilliseconds: 2000
    )
}

final class YashswiAppConfigService {

    static let shared = YashswiAppConfigService()

    private let endpoint = URL(
        string: "https://yashswi.in/api/app_ad_config.php"
    )!

    private init() {}

    // Read-only configuration request.
    // Call only when needed by the application.
    func fetch(
        completion: @escaping (YashswiAppConfiguration) -> Void
    ) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) {
            data, response, error in

            var configuration =
                YashswiAppConfiguration.defaultConfiguration

            defer {
                DispatchQueue.main.async {
                    completion(configuration)
                }
            }

            guard error == nil,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(
                    with: data
                  ) as? [String: Any] else {
                return
            }

            func flag(_ key: String) -> Bool {
                if let value = json[key] as? Bool {
                    return value
                }

                if let value = json[key] as? NSNumber {
                    return value.boolValue
                }

                if let value = json[key] as? String {
                    return ["1", "true", "yes"].contains(
                        value.lowercased()
                    )
                }

                return false
            }

            var duration = 2000

            if let value = json["splash_duration_ms"] as? Int {
                duration = value
            } else if let value =
                        json["splash_duration_ms"] as? String,
                      let parsed = Int(value) {
                duration = parsed
            }

            duration = min(max(duration, 500), 12000)

            var imageURL: URL?

            if let rawURL = json["ad_image_url"] as? String,
               let url = URL(string: rawURL),
               url.scheme?.lowercased() == "https" {
                imageURL = url
            }

            configuration = YashswiAppConfiguration(
                showSplashAd: flag("show_splash_ad"),
                showRewardAd: flag("show_reward_ad"),
                showBannerAd: flag("show_banner_ad"),
                showAd: flag("show_ad"),
                adImageURL: imageURL,
                splashDurationMilliseconds: duration
            )
        }.resume()
    }
}
