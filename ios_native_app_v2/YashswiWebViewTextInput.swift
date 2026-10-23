import UIKit
import WebKit

extension YashswiWebViewController {

    // Supports JavaScript prompt() dialogs used by
    // some website forms.

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let origin = frame.securityOrigin
        let host = origin.host.lowercased()

        let trusted =
            origin.protocol.lowercased() == "https" &&
            (host == "yashswi.in" ||
             host.hasSuffix(".yashswi.in"))

        guard trusted, frame.isMainFrame,
              presentedViewController == nil else {
            completionHandler(nil)
            return
        }

        let alert = UIAlertController(
            title: "YASHSWI",
            message: prompt,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = defaultText
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            ) { _ in
                completionHandler(nil)
            }
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            ) { _ in
                completionHandler(
                    alert.textFields?.first?.text ?? ""
                )
            }
        )

        present(alert, animated: true)
    }
}
