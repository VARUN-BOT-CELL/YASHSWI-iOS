
import Foundation
import WebKit

protocol YashswiJavaScriptBridgeDelegate: AnyObject {
    func bridgeDidRequestLogout()
    func bridgeDidRequestStartTracking()
    func bridgeDidRequestStopTracking(callback: String?)
    func bridgeDidRequestLocationUpdate()
    func bridgeDidRequestRewardAd()
}

final class YashswiJavaScriptBridge: NSObject,
    WKScriptMessageHandler {

    weak var delegate: YashswiJavaScriptBridgeDelegate?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "yashswiBridge" else {
            return
        }

        let origin = message.frameInfo.securityOrigin
        let host = origin.host.lowercased()

        let trustedHost =
            host == "yashswi.in" ||
            host.hasSuffix(".yashswi.in")

        guard message.frameInfo.isMainFrame,
              origin.protocol.lowercased() == "https",
              trustedHost else {
            return
        }

        guard let payload = message.body as? [String: Any],
              let action = payload["action"] as? String else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch action {

            case "logout":
                self.delegate?.bridgeDidRequestLogout()

            case "startLiveTracking":
                self.delegate?.bridgeDidRequestStartTracking()

            case "stopLiveTracking":
                self.delegate?.bridgeDidRequestStopTracking(
                    callback: nil
                )

            case "stopLiveTrackingWithCallback":
                let callback = payload["callback"] as? String
                self.delegate?.bridgeDidRequestStopTracking(
                    callback: callback
                )

            case "forceSendLocation":
                self.delegate?.bridgeDidRequestLocationUpdate()

            case "showRewardAd":
                self.delegate?.bridgeDidRequestRewardAd()

            default:
                break
            }
        }
    }
}
