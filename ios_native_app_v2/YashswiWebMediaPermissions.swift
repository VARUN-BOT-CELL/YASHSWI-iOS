import Foundation
import WebKit

// MARK: - Camera and Microphone Permissions

extension YashswiWebViewController {

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        let host = origin.host.lowercased()

        let trustedHost =
            host == "yashswi.in" ||
            host.hasSuffix(".yashswi.in")

        guard origin.protocol.lowercased() == "https",
              trustedHost,
              frame.isMainFrame else {
            decisionHandler(.deny)
            return
        }

        // Ask for permission rather than silently granting it.
        // iOS manages the required system privacy permission.
        decisionHandler(.prompt)
    }
}
