import UIKit
import WebKit

extension YashswiWebViewController {

    func showOfflineRecovery(
        for webView: WKWebView,
        error: Error
    ) {
        let networkError = error as NSError

        // The failing URL is more reliable than webView.url
        // during provisional navigation failures.
        guard let failingURLString =
                networkError.userInfo[NSURLErrorFailingURLStringErrorKey]
                    as? String,
              let failingURL = URL(string: failingURLString),
              failingURL.scheme?.lowercased() == "https",
              failingURL.host?.lowercased() == "yashswi.in",
              failingURL.path == "/user/manager.php" else {
            return
        }

        // Prevent duplicate or overlapping alerts.
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Connection Unavailable",
            message: """
            Unable to load the YASHSWI dashboard.

            Check your internet connection and try again.
            """,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Retry",
                style: .default
            ) { [weak webView] _ in

                guard let webView = webView,
                      let dashboardURL = URL(
                        string: "https://yashswi.in/user/manager.php"
                      ) else {
                    return
                }

                // Only issue a fresh dashboard GET.
                // Never replay the failed navigation request.
                webView.load(
                    URLRequest(
                        url: dashboardURL,
                        cachePolicy: .reloadIgnoringLocalCacheData
                    )
                )
            }
        )

        present(alert, animated: true)
    }
}