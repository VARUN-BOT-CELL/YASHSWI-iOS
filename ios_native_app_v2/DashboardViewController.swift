
import UIKit

class DashboardViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let primaryColor = UIColor(
        red: 0.12, green: 0.23, blue: 0.54, alpha: 1
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMenuBasedOnRole()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        let headerView = UIView()
        headerView.backgroundColor = primaryColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let name = AppSession.shared.currentUser?.name ?? "User"
        let role = AppSession.shared.currentUser?.role ?? "user"

        let welcomeLabel = UILabel()
        welcomeLabel.text = "Hello, \(name.components(separatedBy: " ").first ?? name) 👋"
        welcomeLabel.font = .boldSystemFont(ofSize: 24)
        welcomeLabel.textColor = .white

        let roleLabel = UILabel()
        roleLabel.text = "Role: \(role.uppercased())"
        roleLabel.font = .systemFont(ofSize: 14)
        roleLabel.textColor = .white

        let headerStack = UIStackView(
            arrangedSubviews: [welcomeLabel, roleLabel]
        )
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 160),

            headerStack.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor, constant: 20
            ),
            headerStack.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor, constant: -20
            ),
            headerStack.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor, constant: -20
            ),

            scrollView.topAnchor.constraint(
                equalTo: headerView.bottomAnchor
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

            stackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 20
            ),
            stackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -20
            ),
            stackView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 20
            ),
            stackView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -20
            ),
            stackView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            )
        ])
    }

    // MARK: - Dashboard

    private func loadMenuBasedOnRole() {

        let role = AppSession.shared.currentUser?
            .role.lowercased() ?? "user"

        addSectionTitle("Personal Workspace 👤")
        addGridButton("Attendance Tracking",
                      color: primaryColor, textColor: .white)
        addGridButton("Leave Management",
                      color: primaryColor, textColor: .white)

        if ["sc", "sm", "asm"].contains(role) {
            addSectionTitle("Service Coordination 🛠️")
            addGridButton("Daily Activity Report")
            addGridButton("Service Reports (FSR)")
            addGridButton("Claim Approvals")
            addGridButton("AMC Master Dashboard")

            addSectionTitle("Inventory & Spares 📦")
            addGridButton("Live Stock Viewer")
            addGridButton("Part Requests")
            addGridButton("Stock Management")

        } else if ["admin", "md", "oh"].contains(role) {
            addSectionTitle("Management Panel 🏛️")
            addGridButton("User Management")
            addGridButton("Live Analytics")
            addGridButton("Machine Database")
            addGridButton("Attendance Reports")
            addGridButton("Manage Products")

        } else if role == "engineer" {
            addSectionTitle("Field Engineering 🔧")
            addGridButton("Submit New FSR")
            addGridButton("My Service History")
            addGridButton("My Petrol Claims")
            addGridButton("Assigned Visits")
            addGridButton("Part Availability")

        } else if role == "sales" {
            addSectionTitle("Sales Portal 📈")
            addGridButton("View Leads")
            addGridButton("Manage Products")
            addGridButton("Visit Schedule")
        }

        addSectionTitle("Account ⚙️")
        addGridButton(
            "Logout",
            color: UIColor(red: 1, green: 0.92, blue: 0.92, alpha: 1),
            textColor: .systemRed
        )
    }

    // MARK: - UI Components

    private func addSectionTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0

        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: container.topAnchor, constant: 16
            ),
            label.bottomAnchor.constraint(
                equalTo: container.bottomAnchor, constant: -8
            ),
            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),
            label.trailingAnchor.constraint(
                equalTo: container.trailingAnchor
            )
        ])

        stackView.addArrangedSubview(container)
    }

    private func addGridButton(
        _ text: String,
        color: UIColor = .white,
        textColor: UIColor = .black
    ) {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.backgroundColor = color
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(
            top: 0, left: 20, bottom: 0, right: 16
        )

        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(
            equalToConstant: 70
        ).isActive = true

        switch text {

        case "Logout":
            button.addTarget(
                self, action: #selector(logoutTapped),
                for: .touchUpInside
            )

        case "Attendance Tracking":
            button.addTarget(
                self, action: #selector(attendanceTapped),
                for: .touchUpInside
            )

        case "Leave Management":
            button.addTarget(
                self, action: #selector(openLeaveWebsite),
                for: .touchUpInside
            )

        case "Service Reports (FSR)", "Submit New FSR":
            button.addTarget(
                self, action: #selector(openFSRWebsite),
                for: .touchUpInside
            )

        case "My Service History":
            button.addTarget(
                self, action: #selector(openFSRHistory),
                for: .touchUpInside
            )

        case "My Petrol Claims":
            button.addTarget(
                self, action: #selector(openPetrolClaims),
                for: .touchUpInside
            )

        case "Live Stock Viewer",
             "Stock Management",
             "Part Availability",
             "Part Requests":
            button.addTarget(
                self, action: #selector(inventoryTapped),
                for: .touchUpInside
            )

        case "Manage Products":
            button.addTarget(
                self, action: #selector(productsTapped),
                for: .touchUpInside
            )

        default:
            button.addTarget(
                self, action: #selector(genericMenuTapped(_:)),
                for: .touchUpInside
            )
        }

        stackView.addArrangedSubview(button)
    }

    // MARK: - Existing Native Screens

    @objc private func attendanceTapped() {
        let controller = AttendanceViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    @objc private func productsTapped() {
        let controller = ProductListViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    @objc private func inventoryTapped() {
        let controller = InventoryViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    // MARK: - Website Feature Integration

    private func openWebsiteFeature(_ path: String) {

        guard AppSession.shared.isAuthenticated else {
            showAlert(
                "Login Required",
                "Please sign in to continue."
            )
            return
        }

        guard let url = URL(
            string: "https://yashswi.in/" + path
        ),
        url.scheme == "https",
        url.host == "yashswi.in" else {
            showAlert(
                "Navigation Error",
                "Unable to open this feature."
            )
            return
        }

        let controller = YashswiWebViewController(
            dashboardURL: url
        )

        // The website opens through the existing
        // WebView implementation and cookie store.
        let navigation = UINavigationController(
            rootViewController: controller
        )

        controller.title = "YASHSWI"
        controller.navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                title: "Close",
                style: .plain,
                target: self,
                action: #selector(closeWebsiteFeature)
            )

        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }

    @objc private func closeWebsiteFeature() {
        dismiss(animated: true)
    }

    @objc private func openLeaveWebsite() {
        openWebsiteFeature("user/apply_leave.php")
    }

    @objc private func openFSRWebsite() {
        openWebsiteFeature("forms/fsr_new.php")
    }

    @objc private func openFSRHistory() {
        openWebsiteFeature("forms/my_fsr.php")
    }

    @objc private func openPetrolClaims() {
        openWebsiteFeature(
            "forms/petrol_allowance/my_allowance_status.php"
        )
    }

    // MARK: - Logout

    @objc private func logoutTapped() {
        AppSession.shared.signOut()

        let defaults = UserDefaults.standard
        ["USER_ROLE", "USER_NAME", "EMP_ID"].forEach {
            defaults.removeObject(forKey: $0)
        }

        if let window = view.window {
            window.rootViewController = LoginViewController()
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Unimplemented Modules

    @objc private func genericMenuTapped(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? "Screen"

        showAlert(
            title,
            "This module is currently under development."
        )
    }

    private func showAlert(
        _ title: String,
        _ message: String
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }
}
