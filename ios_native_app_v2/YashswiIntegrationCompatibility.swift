
import Foundation

extension YashswiBiometricManager {
    var authenticationTitle: String {
        biometricTitle
    }
}

typealias YashswiAppConfig = YashswiAppConfiguration

extension YashswiAppConfiguration {
    var splashDurationMs: Int {
        splashDurationMilliseconds
    }
}

extension YashswiAppConfigService {
    func fetchConfiguration(
        completion: @escaping (YashswiAppConfig) -> Void
    ) {
        fetch(completion: completion)
    }
}

extension YashswiAdvertisementManager {
    func applyConfiguration(
        _ config: YashswiAppConfig
    ) {
        apply(config)
    }
}
