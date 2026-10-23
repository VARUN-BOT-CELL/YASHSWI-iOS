
import UIKit

final class LoginViewController: UIViewController {

    // MARK: - UI Components

    private let empIdTextField = UITextField()
    private let passwordTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let biometricButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var isAuthenticating = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshBiometricButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBiometricButton()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        let titleLabel = UILabel()
        titleLabel.text = "Welcome Back"
        titleLabel.font = .boldSystemFont(ofSize: 30)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text =
            "Sign in to your YASHSWI employee account"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        configureTextField(
            empIdTextField,
            placeholder: "Employee ID"
        )

        empIdTextField.autocapitalizationType = .none
        empIdTextField.autocorrectionType = .no
        empIdTextField.textContentType = .username
        empIdTextField.returnKeyType = .next
        empIdTextField.delegate = self

        configureTextField(
            passwordTextField,
            placeholder: "Password"
        )

        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .done
        passwordTextField.delegate = self

        loginButton.setTitle("Sign In", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)

        loginButton.backgroundColor = UIColor(
            red: 0.12,
            green: 0.23,
            blue: 0.54,
            alpha: 1
        )

        loginButton.titleLabel?.font =
            .boldSystemFont(ofSize: 17)

        loginButton.layer.cornerRadius = 12
        loginButton.heightAnchor.constraint(
            equalToConstant: 54
        ).isActive = true

        loginButton.addTarget(
            self,
            action: #selector(loginTapped),
            for: .touchUpInside
        )

        biometricButton.setTitle(
            "Sign In with Face ID / Touch ID",
            for: .normal
        )

        biometricButton.titleLabel?.font =
            .systemFont(ofSize: 16, weight: .semibold)

        biometricButton.heightAnchor.constraint(
            equalToConstant: 48
        ).isActive = true

        biometricButton.addTarget(
            self,
            action: #selector(biometricLoginTapped),
            for: .touchUpInside
        )

        loadingIndicator.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            empIdTextField,
            passwordTextField,
            loginButton,
            biometricButton,
            loadingIndicator
        ])

        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            stack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 28
            ),
            stack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -28
            ),
            stack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 80
            ),
            stack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -32
            ),
            stack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -56
            )
        ])
    }

    // MARK: - Text Field Configuration

    private func configureTextField(
        _ field: UITextField,
        placeholder: String
    ) {
        field.placeholder = placeholder
        field.backgroundColor = .secondarySystemGroupedBackground
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 16)

        field.heightAnchor.constraint(
            equalToConstant: 54
        ).isActive = true
    }

    // MARK: - Biometric Button Availability

    private func refreshBiometricButton() {
        let enabled =
            YashswiBiometricCredentialStore.shared.isEnabled

        biometricButton.isHidden = !enabled

        guard enabled else { return }

        let title =
            YashswiBiometricManager.shared.authenticationTitle

        biometricButton.setTitle(
            "Sign In with \(title)",
            for: .normal
        )
    }

    // MARK: - Standard Login

    @objc private func loginTapped() {
        guard !isAuthenticating else { return }
        view.endEditing(true)

        let empId = (empIdTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let password = passwordTextField.text ?? ""

        guard !empId.isEmpty, !password.isEmpty else {
            showAlert(
                message: "Please enter your Employee ID and password."
            )
            return
        }

        performLogin(
            empId: empId,
            password: password,
            fromBiometrics: false
        )
    }

    // MARK: - Biometric Login

    @objc private func biometricLoginTapped() {
        guard !isAuthenticating else { return }
        view.endEditing(true)
        setLoading(true)

        YashswiBiometricCredentialStore.shared.unlock {
            [weak self] result in

            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    self.setLoading(false)
                    self.showAlert(message: error.localizedDescription)

                case .success(let credentials):
                    self.performLogin(
                        empId: credentials.employeeId,
                        password: credentials.password,
                        fromBiometrics: true
                    )
                }
            }
        }
    }

    // MARK: - Shared Server Authentication

    private func performLogin(
        empId: String,
        password: String,
        fromBiometrics: Bool
    ) {
        let deviceId = DeviceIdentifier.shared.value

        guard !deviceId.isEmpty else {
            setLoading(false)
            showAlert(
                message: "Unable to access the secure device identifier."
            )
            return
        }

        setLoading(true)

        ApiService.shared.performAndroidCompatibleLogin(
            empId: empId,
            password: password,
            deviceId: deviceId
        ) { [weak self] result in

            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {

                case .failure(let error):
                    self.setLoading(false)
                    self.showAlert(
                        message: error.localizedDescription
                    )

                case .success(let data):
                    let response: AndroidLoginResponse

                    do {
                        response = try AndroidLoginResponse.parse(data)
                    } catch {
                        self.setLoading(false)
                        self.showAlert(
                            message: "Unable to read the login server response."
                        )
                        return
                    }

                    guard response.success else {
                        self.setLoading(false)
                        self.showAlert(
                            message: response.message ?? "Login failed."
                        )
                        return
                    }

                    guard let dashboardURL =
                        response.resolvedDashboardURL else {

                        self.setLoading(false)
                        self.showAlert(
                            message: "Invalid dashboard URL received."
                        )
                        return
                    }

                    YashswiSessionBridge.shared.synchronizeCookies {
                        [weak self] cookiesAvailable in

                        DispatchQueue.main.async {
                            guard let self = self else { return }

                            self.setLoading(false)

                            guard cookiesAvailable else {
                                self.showAlert(
                                    message: """
                                    Login succeeded, but no website \
                                    session cookie was found. Session \
                                    integration needs verification.
                                    """
                                )
                                return
                            }

                            AppSession.shared
                                .setAuthenticatedEmployeeId(empId)

                            self.passwordTextField.text = nil

                            if fromBiometrics {
                                self.openDashboard(dashboardURL)
                            } else {
                                self.offerBiometricEnrollment(
                                    empId: empId,
                                    password: password,
                                    dashboardURL: dashboardURL
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Employee Biometric Consent

    private func offerBiometricEnrollment(
        empId: String,
        password: String,
        dashboardURL: URL
    ) {
        guard YashswiBiometricManager.shared.isAvailable else {
            openDashboard(dashboardURL)
            return
        }

        let title =
            YashswiBiometricManager.shared.authenticationTitle

        let alert = UIAlertController(
            title: "Enable \(title) Login?",
            message: """
            Allow secure biometric login on this iPhone?

            Your login credentials will be protected by \
            iOS Keychain and can only be unlocked using \
            the enrolled biometrics on this device.

            You can continue without enabling this feature.
            """,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Not Now",
                style: .cancel
            ) { [weak self] _ in
                self?.openDashboard(dashboardURL)
            }
        )

        alert.addAction(
            UIAlertAction(
                title: "Enable",
                style: .default
            ) { [weak self] _ in

                guard let self = self else { return }

                let saved =
                    YashswiBiometricCredentialStore.shared.enable(
                        employeeId: empId,
                        password: password
                    )

                if !saved {
                    // Standard login has already succeeded.
                    // Biometric enrollment is optional.
                    NSLog(
                        "YASHSWI biometric enrollment was not completed."
                    )
                }

                self.openDashboard(dashboardURL)
            }
        )

        present(alert, animated: true)
    }

    // MARK: - Open Dashboard

    private func openDashboard(_ dashboardURL: URL) {
        let webVC = YashswiWebViewController(
            dashboardURL: dashboardURL
        )

        if let window = view.window {
            window.rootViewController = webVC
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Loading State

    private func setLoading(_ loading: Bool) {
        isAuthenticating = loading
        loginButton.isEnabled = !loading
        biometricButton.isEnabled = !loading

        loginButton.alpha = loading ? 0.6 : 1
        biometricButton.alpha = loading ? 0.6 : 1

        empIdTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading

        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Alerts

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Employee Login",
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

// MARK: - Keyboard Navigation

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(
        _ textField: UITextField
    ) -> Bool {
        if textField === empIdTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            loginTapped()
        }

        return true
    }
}
