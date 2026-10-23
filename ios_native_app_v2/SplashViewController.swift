
import UIKit

final class SplashViewController: UIViewController {

    // MARK: - UI

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let splashAdImageView = UIImageView()

    // MARK: - State

    private var hasNavigated = false
    private var imageRequest: URLSessionDataTask?

    private let splashStartDate = Date()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadAppConfiguration()
    }

    deinit {
        imageRequest?.cancel()
    }

    // MARK: - UI Setup

    private func setupUI() {

        view.backgroundColor = .systemBackground

        titleLabel.text = "YASHSWI"
        titleLabel.font = .systemFont(
            ofSize: 40,
            weight: .heavy
        )
        titleLabel.textColor = UIColor(
            red: 0.12,
            green: 0.23,
            blue: 0.54,
            alpha: 1
        )
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Employee Management"
        subtitleLabel.font = .systemFont(
            ofSize: 15,
            weight: .medium
        )
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()

        splashAdImageView.contentMode = .scaleAspectFit
        splashAdImageView.clipsToBounds = true
        splashAdImageView.layer.cornerRadius = 12
        splashAdImageView.isHidden = true

        let brandingStack = UIStackView(
            arrangedSubviews: [
                titleLabel,
                subtitleLabel
            ]
        )

        brandingStack.axis = .vertical
        brandingStack.spacing = 12
        brandingStack.alignment = .center

        brandingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        splashAdImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(brandingStack)
        view.addSubview(loadingIndicator)
        view.addSubview(splashAdImageView)

        NSLayoutConstraint.activate([

            brandingStack.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            brandingStack.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -90
            ),

            brandingStack.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24
            ),

            brandingStack.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            ),

            splashAdImageView.topAnchor.constraint(
                equalTo: brandingStack.bottomAnchor,
                constant: 24
            ),

            splashAdImageView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            splashAdImageView.widthAnchor.constraint(
                lessThanOrEqualTo: view.widthAnchor,
                multiplier: 0.85
            ),

            splashAdImageView.widthAnchor.constraint(
                equalToConstant: 280
            ),

            splashAdImageView.heightAnchor.constraint(
                equalToConstant: 160
            ),

            loadingIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            loadingIndicator.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -55
            )
        ])
    }

    // MARK: - Fetch Remote App Configuration

    private func loadAppConfiguration() {

        // A fallback ensures the employee can reach login
        // even if the remote configuration server hangs.
        scheduleNavigation(after: 12)

        YashswiAppConfigService.shared.fetchConfiguration {
            [weak self] config in

            guard let self = self,
                  !self.hasNavigated else {
                return
            }

            self.applyConfiguration(config)
        }
    }

    // MARK: - Apply App Configuration

   private func applyConfiguration(
    _ config: YashswiAppConfig
) {

    // Apply advertisement settings from the server.
    // This does not display Google ads yet.
    YashswiAdvertisementManager.shared
        .applyConfiguration(config)

    if config.showAd,
       let imageURL = config.adImageURL {
            loadSplashImage(from: imageURL)
        }

        // Splash timing is configured in milliseconds.
        let duration = TimeInterval(
            config.splashDurationMs
        ) / 1000.0

        let elapsed = Date().timeIntervalSince(
            splashStartDate
        )

        let remaining = max(0, duration - elapsed)

        scheduleNavigation(after: remaining)
    }

    // MARK: - Splash Advertisement Image

    private func loadSplashImage(from url: URL) {

        guard url.scheme?.lowercased() == "https" else {
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6

        imageRequest = URLSession.shared.dataTask(
            with: request
        ) { [weak self] data, response, error in

            guard error == nil,
                  let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode),
                  let mimeType = response.mimeType?.lowercased(),
                  ["image/png", "image/jpeg", "image/webp"]
                    .contains(mimeType),
                  let data = data,
                  data.count <= 5_000_000,
                  let image = UIImage(data: data) else {
                return
            }

            DispatchQueue.main.async {

                guard let self = self,
                      !self.hasNavigated else {
                    return
                }

                self.splashAdImageView.image = image
                self.splashAdImageView.isHidden = false
            }

        }

        imageRequest?.resume()
    }

    // MARK: - Navigation Scheduling

    private func scheduleNavigation(
        after delay: TimeInterval
    ) {

        DispatchQueue.main.asyncAfter(
            deadline: .now() + max(0, delay)
        ) { [weak self] in

            self?.navigateToLogin()
        }
    }

    // MARK: - Open Employee Login

    private func navigateToLogin() {

        guard !hasNavigated else {
            return
        }

        guard let window = view.window else {
            return
        }

        hasNavigated = true

        imageRequest?.cancel()
        loadingIndicator.stopAnimating()

        // Local session flags are not sufficient to
        // prove that the backend WebView session is valid.
        //
        // The employee may use Face ID / Touch ID on
        // LoginViewController, which authenticates again
        // against the existing login API.
        window.rootViewController = LoginViewController()
        window.makeKeyAndVisible()
    }
}
