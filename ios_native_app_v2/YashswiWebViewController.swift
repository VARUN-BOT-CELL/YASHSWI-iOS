
import UIKit
import WebKit
import CoreLocation

final class YashswiWebViewController: UIViewController,
    WKNavigationDelegate,
    WKUIDelegate,
    WKDownloadDelegate {

    // MARK: - Properties

    private let dashboardURL: URL
    private var webView: WKWebView!
    private let pageLoadingIndicator = UIProgressView(progressViewStyle: .default)
    private var isLoggingOut = false

    private let javaScriptBridge = YashswiJavaScriptBridge()

    private var downloads: [
        ObjectIdentifier: (download: WKDownload, url: URL)
    ] = [:]

    // MARK: - Initialization

    init(dashboardURL: URL) {
        self.dashboardURL = dashboardURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupWebView()
        setupPageLoadingIndicator()
        setupLocationMonitoring()

        // Inspect locally queued records only.
        // Production GPS and Punch Out uploads remain disabled.
        YashswiGPSQueueCoordinator.shared.configure()
        YashswiPunchOutSyncCoordinator.shared.configure()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        loadDashboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        webView?.configuration.userContentController
            .removeScriptMessageHandler(forName: "yashswiBridge")
    }

    // MARK: - WebView Setup

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()

        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        configuration.userContentController.add(
            javaScriptBridge,
            name: "yashswiBridge"
        )

        let compatibilityScript = """
        (function() {
            if (window.top !== window) return;

            const host = window.location.hostname.toLowerCase();

            if (window.location.protocol !== 'https:' ||
                (host !== 'yashswi.in' &&
                 !host.endsWith('.yashswi.in'))) {
                return;
            }

            function send(action, additionalData) {
                const handler =
                    window.webkit &&
                    window.webkit.messageHandlers &&
                    window.webkit.messageHandlers.yashswiBridge;

                if (!handler) return;

                handler.postMessage(
                    Object.assign(
                        { action: action },
                        additionalData || {}
                    )
                );
            }

            const existingAndroidApp = window.AndroidApp || {};

            window.AndroidApp = Object.assign(existingAndroidApp, {
                startLiveTracking: function() {
                    send('startLiveTracking');
                },

                stopLiveTracking: function() {
                    send('stopLiveTracking');
                },

                stopLiveTrackingWithCallback: function(callbackFn) {
                    send('stopLiveTrackingWithCallback', {
                        callback: String(callbackFn)
                    });
                },

                forceSendLocation: function() {
                    send('forceSendLocation');
                },

                logout: function() {
                    send('logout');
                },

                getDeviceId: function() {
                    return window.__yashswiDeviceId || '';
                },

                getDeviceID: function() {
                    return window.__yashswiDeviceId || '';
                },

                isLocationEnabled: function() {
                    return window.__yashswiLocationEnabled === true;
                },

                showRewardAd: function() {
                    send('showRewardAd');
                }
            });
        })();
        """

        configuration.userContentController.addUserScript(
            WKUserScript(
                source: compatibilityScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        // MARK: - Initial Location Status

        let locationEnabled =
            YashswiLocationManager.shared.isLocationAvailable

        let locationStatusScript = """
        (function() {
            const host = window.location.hostname.toLowerCase();

            if (window.top !== window ||
                window.location.protocol !== 'https:' ||
                (host !== 'yashswi.in' &&
                 !host.endsWith('.yashswi.in'))) {
                return;
            }

            window.__yashswiLocationEnabled =
                \(locationEnabled ? "true" : "false");
        })();
        """

        configuration.userContentController.addUserScript(
            WKUserScript(
                source: locationStatusScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        // MARK: - Device Identifier

        let deviceId = DeviceIdentifier.shared.value

        if !deviceId.isEmpty,
           let jsonData = try? JSONSerialization.data(
                withJSONObject: [deviceId],
                options: [.fragmentsAllowed]
           ),
           let jsonArray = String(
                data: jsonData,
                encoding: .utf8
           ) {

            let deviceScript = """
            (function() {
                const host = window.location.hostname.toLowerCase();

                if (window.top !== window ||
                    window.location.protocol !== 'https:' ||
                    (host !== 'yashswi.in' &&
                     !host.endsWith('.yashswi.in'))) {
                    return;
                }

                const ids = \(jsonArray);
                window.__yashswiDeviceId = ids[0] || '';
            })();
            """

            configuration.userContentController.addUserScript(
                WKUserScript(
                    source: deviceScript,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
            )
        }

        javaScriptBridge.delegate = self

        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            webView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            webView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            webView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    // MARK: - Page Loading Indicator

    private func setupPageLoadingIndicator() {
        pageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        pageLoadingIndicator.progressTintColor = UIColor(
            red: 0.12,
            green: 0.23,
            blue: 0.54,
            alpha: 1
        )

        pageLoadingIndicator.trackTintColor = .clear
        pageLoadingIndicator.progress = 0
        pageLoadingIndicator.isHidden = true

        view.addSubview(pageLoadingIndicator)

        NSLayoutConstraint.activate([
            pageLoadingIndicator.topAnchor.constraint(
                equalTo: webView.topAnchor
            ),
            pageLoadingIndicator.leadingAnchor.constraint(
                equalTo: webView.leadingAnchor
            ),
            pageLoadingIndicator.trailingAnchor.constraint(
                equalTo: webView.trailingAnchor
            )
        ])
    }

    private func showPageLoading() {
        guard !isLoggingOut else { return }

        pageLoadingIndicator.progress = 0.15
        pageLoadingIndicator.isHidden = false
    }

    private func hidePageLoading() {
        pageLoadingIndicator.progress = 1
        pageLoadingIndicator.isHidden = true
    }

    // MARK: - Load Dashboard

    private func loadDashboard() {
        webView.load(URLRequest(url: dashboardURL))
    }

    // MARK: - URL Helpers

    private func isYashswiHost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()

        return normalizedHost == "yashswi.in" ||
            normalizedHost.hasSuffix(".yashswi.in")
    }

    private func isYashswiCookie(_ cookie: HTTPCookie) -> Bool {
        let domain = cookie.domain
            .lowercased()
            .trimmingCharacters(
                in: CharacterSet(charactersIn: ".")
            )

        return isYashswiHost(domain)
    }

    private func isDownloadURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        let fileName = url.lastPathComponent.lowercased()

        let extensions = [
            ".pdf",
            ".xlsx",
            ".xls",
            ".csv"
        ]

        if extensions.contains(where: {
            fileName.hasSuffix($0)
        }) {
            return true
        }

        return path.contains("download") ||
            path.contains("print_report") ||
            path.contains("export")
    }

    // MARK: - Page Navigation Progress

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        showPageLoading()
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        hidePageLoading()
        refreshWebsiteLocationStatus()
    }

    // MARK: - Navigation Handling

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard !isLoggingOut else {
            decisionHandler(.cancel)
            return
        }

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        // Phone, WhatsApp and email links.
        if ["tel", "whatsapp", "mailto"].contains(scheme) {
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
            return
        }

        if scheme == "about" &&
            url.absoluteString == "about:blank" {
            decisionHandler(.allow)
            return
        }

        guard scheme == "https" || scheme == "http" else {
            decisionHandler(.cancel)
            return
        }

        let isYashswi = isYashswiHost(host)

        // Never load the employee portal over an insecure connection.
        // Do not silently upgrade a request that might contain POST data.
        if isYashswi && scheme != "https" {
            decisionHandler(.cancel)
            showError("The YASHSWI portal requires a secure HTTPS connection.")
            return
        }

        // Detect website logout.
        if isYashswi &&
            (path.hasSuffix("/auth/login.php") ||
             path.hasSuffix("/logout.php")) {

            decisionHandler(.cancel)
            completeLocalLogout()
            return
        }

        // Keep external websites outside the app.
        if !isYashswi {
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
            return
        }

        // Download known GET reports.
        // Never convert a POST submission to GET.
        let method = navigationAction.request
            .httpMethod?.uppercased() ?? "GET"

        if method == "GET" && isDownloadURL(url) {
            decisionHandler(.download)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - New Window Handling

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {

        guard !isLoggingOut,
              navigationAction.targetFrame == nil,
              let url = navigationAction.request.url else {
            return nil
        }

        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""

        // External communication links.
        if ["tel", "whatsapp", "mailto"].contains(scheme) {
            UIApplication.shared.open(url)
            return nil
        }

        // Open external HTTP(S) websites in the system browser.
        guard scheme == "https" || scheme == "http" else {
            return nil
        }

        if isYashswiHost(host) {
            guard scheme == "https" else {
                showError("The YASHSWI portal requires a secure HTTPS connection.")
                return nil
            }
            // Reuse the existing WebView. Its navigation
            // delegate still validates logout and downloads.
            webView.load(navigationAction.request)
        } else {
            UIApplication.shared.open(url)
        }

        return nil
    }

    // MARK: - Download Response Handling

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        guard !isLoggingOut else {
            decisionHandler(.cancel)
            return
        }

        let response = navigationResponse.response

        guard let url = response.url,
              let host = url.host,
              isYashswiHost(host) else {
            decisionHandler(.allow)
            return
        }

        let mimeType = response.mimeType?.lowercased() ?? ""

        let downloadableTypes = [
            "application/pdf",
            "application/octet-stream",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "text/csv"
        ]

        var isAttachment = false

        if let httpResponse = response as? HTTPURLResponse {
            let disposition = httpResponse.value(
                forHTTPHeaderField: "Content-Disposition"
            )?.lowercased() ?? ""

            isAttachment = disposition.contains("attachment")
        }

        if navigationResponse.isForMainFrame &&
            (isAttachment ||
             downloadableTypes.contains(mimeType) ||
             !navigationResponse.canShowMIMEType) {

            decisionHandler(.download)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - Download Delegates

    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        hidePageLoading()
        download.delegate = self
    }

    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        hidePageLoading()
        download.delegate = self
    }

    // MARK: - Download Destination

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let rawName = (suggestedFilename as NSString)
            .lastPathComponent

        let fileName: String

        if rawName.isEmpty ||
            rawName == "." ||
            rawName == ".." {
            fileName = "YashswiReport"
        } else {
            fileName = rawName
        }

        let folder = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "YashswiDownloads",
                isDirectory: true
            )
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        do {
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )

            let destination = folder
                .appendingPathComponent(fileName)

            downloads[ObjectIdentifier(download)] = (
                download: download,
                url: destination
            )

            completionHandler(destination)

        } catch {
            completionHandler(nil)
            showError(
                "Unable to prepare the report download."
            )
        }
    }

    // MARK: - Download Completed

    func downloadDidFinish(_ download: WKDownload) {
        let identifier = ObjectIdentifier(download)

        guard let item = downloads.removeValue(
            forKey: identifier
        ) else {
            return
        }

        let fileURL = item.url

        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            showError("Downloaded report was not found.")
            return
        }

        let shareController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let popover = shareController
            .popoverPresentationController {

            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
        }

        present(shareController, animated: true)
    }

    // MARK: - Download Failed

    func download(
        _ download: WKDownload,
        didFailWithError error: Error,
        resumeData: Data?
    ) {
        downloads.removeValue(
            forKey: ObjectIdentifier(download)
        )

        if (error as NSError).code == NSURLErrorCancelled {
            return
        }

        showError(
            "Report download failed: \(error.localizedDescription)"
        )
    }

    // MARK: - Background Location Permission

    private func showBackgroundLocationPermissionPrompt() {
        let locationManager = YashswiLocationManager.shared

        guard !locationManager.hasBackgroundLocationPermission else {
            return
        }

        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Background Location Access",
            message: """
            YASHSWI uses your location during an active attendance \
            shift to record work-related location updates.

            Allowing background location helps tracking continue \
            when the app is not on screen.

            Tracking should stop when your attendance shift ends. \
            You can manage permission in iPhone Settings.
            """,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Not Now",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Continue",
                style: .default
            ) { _ in
                locationManager.requestBackgroundLocationPermission()
            }
        )

        present(alert, animated: true)
    }

    // MARK: - Location-Off Monitoring

    private func setupLocationMonitoring() {
        YashswiLocationManager.shared.onLocationDisabled = {
            [weak self] in

            DispatchQueue.main.async {
                guard let self = self,
                      !self.isLoggingOut else {
                    return
                }

                self.showLocationDisabledAlert()
            }
        }
    }

    // MARK: - Location-Off Punch Out Preparation

    private func confirmLocationOffPunchOut() {
        guard !isLoggingOut else {
            return
        }

        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Confirm Punch Out",
            message: """
            Do you want to request attendance Punch Out?

            Your request will be stored locally.
            Attendance will not be confirmed closed until
            the server accepts it.
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
                title: "Confirm",
                style: .destructive
            ) { [weak self] _ in
                self?.prepareLocationOffPunchOut()
            }
        )

        present(alert, animated: true)
    }

    private func prepareLocationOffPunchOut() {
        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {

            showError("Employee login is required.")
            return
        }

        let deviceId = DeviceIdentifier.shared.value

        guard !deviceId.isEmpty else {
            showError("Device ID is unavailable.")
            return
        }

        let saved =
            YashswiOfflinePunchOutStore.shared
                .savePendingPunchOut(
                    employeeId: employeeId,
                    deviceId: deviceId
                )

        guard saved else {
            showError(
                "Unable to save the Punch Out request. Please try again."
            )
            return
        }

        YashswiLocationManager.shared.stopTracking()

        showError(
            "Punch Out request saved on this device. Attendance is not yet confirmed closed. Please verify your attendance status when service is available."
        )
    }

    // MARK: - Location Disabled Alert

    private func showLocationDisabledAlert() {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Location Disabled",
            message: """
            Your device location is unavailable.

            GPS tracking has been stopped. Please enable \
            Location Services to resume tracking.

            If your attendance shift is still active, \
            review its status before continuing.
            """,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Open Settings",
                style: .default
            ) { _ in
                guard let settingsURL = URL(
                    string: UIApplication.openSettingsURLString
                ) else {
                    return
                }

                UIApplication.shared.open(settingsURL)
            }
        )

        alert.addAction(
            UIAlertAction(
                title: "Punch Out",
                style: .destructive
            ) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.confirmLocationOffPunchOut()
                }
            }
        )

        present(alert, animated: true)
    }

    // MARK: - Foreground Location Check

    @objc private func applicationDidBecomeActive() {
        guard !isLoggingOut else {
            return
        }

        YashswiLocationManager.shared
            .checkLocationAvailability()

        refreshWebsiteLocationStatus()

        YashswiPunchOutSyncCoordinator.shared
            .inspectPendingRequests()
    }

    // MARK: - Website Location Status

    private func refreshWebsiteLocationStatus() {
        guard !isLoggingOut, webView != nil else {
            return
        }

        let enabled =
            YashswiLocationManager.shared.isLocationAvailable

        let script = """
        (function() {
            const host = window.location.hostname.toLowerCase();

            if (window.top !== window ||
                window.location.protocol !== 'https:' ||
                (host !== 'yashswi.in' &&
                 !host.endsWith('.yashswi.in'))) {
                return;
            }

            window.__yashswiLocationEnabled =
                \(enabled ? "true" : "false");
        })();
        """

        webView.evaluateJavaScript(
            script,
            completionHandler: nil
        )
    }

    // MARK: - Local Logout

    private func completeLocalLogout() {
        guard !isLoggingOut else { return }

        isLoggingOut = true

        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)

        let locationManager = YashswiLocationManager.shared
        locationManager.stopTracking()
        locationManager.onLocationDisabled = nil

        // Keep queued GPS and Punch Out records intact.
        // Clear saved biometric login credentials.
        YashswiBiometricCredentialStore.shared.clear()

        AppSession.shared.signOut()

        let cookieStore = WKWebsiteDataStore
            .default()
            .httpCookieStore

        cookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }

            let relevantCookies = cookies.filter {
                self.isYashswiCookie($0)
            }

            let group = DispatchGroup()

            for cookie in relevantCookies {
                group.enter()

                cookieStore.delete(cookie) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let httpStorage = HTTPCookieStorage.shared

                for cookie in httpStorage.cookies ?? [] {
                    if self.isYashswiCookie(cookie) {
                        httpStorage.deleteCookie(cookie)
                    }
                }

                self.downloads.removeAll()

                if let window = self.view.window {
                    window.rootViewController =
                        LoginViewController()
                    window.makeKeyAndVisible()
                }
            }
        }
    }

    // MARK: - JavaScript Alerts

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard !isLoggingOut,
              let host = frame.request.url?.host,
              isYashswiHost(host) else {
            completionHandler()
            return
        }

        let alert = UIAlertController(
            title: "YASHSWI",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            ) { _ in
                completionHandler()
            }
        )

        if presentedViewController == nil {
            present(alert, animated: true)
        } else {
            completionHandler()
        }
    }

    // MARK: - JavaScript Confirmation

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard !isLoggingOut,
              let host = frame.request.url?.host,
              isYashswiHost(host) else {
            completionHandler(false)
            return
        }

        let alert = UIAlertController(
            title: "Confirm",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            ) { _ in
                completionHandler(false)
            }
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            ) { _ in
                completionHandler(true)
            }
        )

        if presentedViewController == nil {
            present(alert, animated: true)
        } else {
            completionHandler(false)
        }
    }

    // MARK: - Web Content Process Recovery

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        hidePageLoading()
        guard !isLoggingOut else { return }

        // Never auto-reload here: the previous navigation may have been
        // a form submission (for example, attendance or an FSR entry).
        // Automatic retry could duplicate a production submission.
        showError(
            "The dashboard was interrupted. Please reopen the page after " +
            "checking whether your last action was saved."
        )
    }

    // MARK: - Navigation Errors

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        hidePageLoading()

        guard !isLoggingOut else { return }

        if (error as NSError).code == NSURLErrorCancelled {
            return
        }

        let networkError = error as NSError

        if networkError.domain == NSURLErrorDomain &&
            [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost
            ].contains(networkError.code) {

            showOfflineRecovery(for: webView, error: error)
        } else {
            showError(error.localizedDescription)
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        hidePageLoading()

        guard !isLoggingOut else { return }

        if (error as NSError).code == NSURLErrorCancelled {
            return
        }

        let networkError = error as NSError

        if networkError.domain == NSURLErrorDomain &&
            [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost
            ].contains(networkError.code) {

            showOfflineRecovery(for: webView, error: error)
        } else {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Alerts

    private func showError(_ message: String) {
        guard !isLoggingOut else { return }

        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "YASHSWI",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        present(alert, animated: true)
    }
}

// MARK: - JavaScript Bridge Delegate

extension YashswiWebViewController:
    YashswiJavaScriptBridgeDelegate {

    // MARK: - Logout

    func bridgeDidRequestLogout() {
        completeLocalLogout()
    }

    // MARK: - Start GPS Tracking

    func bridgeDidRequestStartTracking() {
        guard !isLoggingOut else {
            return
        }

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {

            showError(
                "Please log in before starting GPS tracking."
            )
            return
        }

        let locationManager = YashswiLocationManager.shared

        if locationManager.isTracking {
            return
        }

        guard locationManager.isLocationAvailable else {
            locationManager.requestPermission()

            showError(
                "Location permission is required for attendance tracking. Please allow location access and try again."
            )
            return
        }

        let started = locationManager.startTracking()

        guard started else {
            showError(
                "Unable to start GPS tracking. Please check your location settings."
            )
            return
        }

        if !locationManager.hasBackgroundLocationPermission {
            showBackgroundLocationPermissionPrompt()
        }
    }

    // MARK: - Stop GPS Tracking

    func bridgeDidRequestStopTracking(callback: String?) {
        guard !isLoggingOut else {
            return
        }

        YashswiLocationManager.shared.stopTracking()

        // Native GPS stopping is not server-confirmed
        // attendance Punch Out.
        //
        // Preserve queued GPS points and do not invoke
        // a website success callback until its server
        // contract has been verified.
        _ = callback
    }

    // MARK: - Manual Location Update

    func bridgeDidRequestLocationUpdate() {
        guard !isLoggingOut else {
            return
        }

        let locationManager = YashswiLocationManager.shared

        guard locationManager.isTracking else {
            showError(
                "Start attendance GPS tracking before requesting a location update."
            )
            return
        }

        guard locationManager.isLocationAvailable else {
            showError(
                "Location is unavailable. Please enable location access."
            )
            return
        }

        // Obtain a fresh location locally.
        // Do not submit it to production automatically.
        locationManager.requestCurrentLocation()
    }

    // MARK: - Reward Advertisement

    func bridgeDidRequestRewardAd() {
        showError(
            "Rewarded advertisements are not available yet."
        )
    }
}
