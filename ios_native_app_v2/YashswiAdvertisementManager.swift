
import Foundation

final class YashswiAdvertisementManager {

    static let shared = YashswiAdvertisementManager()

    private(set) var configuration =
        YashswiAppConfiguration.defaultConfiguration

    private init() {}

    func apply(_ newConfiguration: YashswiAppConfiguration) {
        configuration = newConfiguration
    }

    var shouldShowSplashAdvertisement: Bool {
        configuration.showAd && configuration.showSplashAd
    }

    var shouldShowBannerAdvertisement: Bool {
        configuration.showAd && configuration.showBannerAd
    }

    var shouldShowRewardAdvertisement: Bool {
        configuration.showAd && configuration.showRewardAd
    }

    var splashDurationMilliseconds: Int {
        configuration.splashDurationMilliseconds
    }

    var advertisementImageURL: URL? {
        configuration.adImageURL
    }

    // AdMob iOS ad units must be configured separately.
    // No live advertising SDK is initialized here.
    // Rewarded ads are not considered completed by this manager.
}
