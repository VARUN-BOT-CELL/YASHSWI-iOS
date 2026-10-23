
import UIKit

class DashboardViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMenuBasedOnRole()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(
            white: 0.96,
            alpha: 1.0
        )

        // Header
        let headerView = UIView()
        headerView.backgroundColor = UIColor(
            red: 0.12,
            green: 0.23,
            blue: 0.54,
            alpha: 1.0
        )
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Logged-in employee
        let name = AppSession.shared.currentUser?.name ?? "User"
        let role = AppSession.shared.currentUser?.role.lowercased() ?? "user"

        let welcomeLabel = UILabel()
        welcomeLabel.text =
            "Hello, \(name.components(separatedBy: " ").first ?? name) 👋"
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 24)
        welcomeLabel.textColor = .white

        let roleLabel = UILabel()
        roleLabel.text = "Role: \(role.uppercased())"
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .lightText

        let headerStack = UIStackView(
            arrangedSubviews: [welcomeLabel, roleLabel]
        )
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(headerStack)

        // Main scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            headerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            headerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            headerView.heightAnchor.constraint(
                equalToConstant: 160
            ),

            headerStack.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor,
                constant: 20
            ),
            headerStack.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor,
                constant: -20
            ),
            headerStack.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: -20
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
                equalTo: scrollView.topAnchor,
                constant: 20
            ),
            stackView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor,
                constant: 20
            ),
            stackView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor,
                constant: -20
            ),
            stackView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor,
                constant: -20
            ),
            stackView.widthAnchor.constraint(
                equalTo: scrollView.widthAnchor,
                constant: -40
            )
        ])
    }

    // MARK: - Role-Based Dashboard

    private func loadMenuBasedOnRole() {

        let role = AppSession.shared.currentUser?
            .role.lowercased() ?? "user"

        // Personal Workspace
        addSectionTitle("Personal Workspace 👤")

        addGridButton(
            "Attendance Tracking",
            color: UIColor(
                red: 0.26,
                green: 0.22,
                blue: 0.79,
                alpha: 1.0
            ),
            textColor: .white
        )

        addGridButton(
            "Leave Management",
            color: UIColor(
                red: 0.26,
                green: 0.22,
                blue: 0.79,
                alpha: 1.0
            ),
            textColor: .white
        )

        // Service Coordination
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

        // Account
        addSectionTitle("Account ⚙️")

        addGridButton(
            "Logout",
            color: UIColor(
                red: 1.0,
                green: 0.92,
                blue: 0.92,
                alpha: 1.0
            ),
            textColor: .systemRed
        )
    }

    // MARK: - Section Title

    private func addSectionTitle(_ title: String) {

        let label = UILabel()
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .darkGray

        let paddingView = UIView()
        paddingView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: paddingView.topAnchor,
                constant: 16
            ),
            label.bottomAnchor.constraint(
                equalTo: paddingView.bottomAnchor,
                constant: -8
            ),
            label.leadingAnchor.constraint(
                equalTo: paddingView.leadingAnchor
            )
        ])

        stackView.addArrangedSubview(paddingView)
    }

    // MARK: - Dashboard Buttons

    private func addGridButton(
        _ text: String,
        color: UIColor = .white,
        textColor: UIColor = .black
    ) {

        let button = UIButton(type: .system)

        button.setTitle(text, for: .normal)
        button.setTitleColor(textColor, for: .normal)

        button.backgroundColor = color
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)

        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: 20,
            bottom: 0,
            right: 0
        )

        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(
            width: 0,
            height: 2
        )
        button.layer.shadowRadius = 4

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(
            equalToConstant: 70
        ).isActive = true

        // Button navigation
        if text == "Logout" {

            button.addTarget(
                self,
                action: #selector(logoutTapped),
                for: .touchUpInside
            )

      
} else if text == "Attendance Tracking" {

    button.addTarget(
        self,
        action: #selector(attendanceTapped),
        for: .touchUpInside
    )

} else if text == "Leave Management" {

    button.addTarget(
        self,
        action: #selector(leaveManagementTapped),
        for: .touchUpInside
    )
    
} else if text == "Service Reports (FSR)" ||
          text == "Submit New FSR" {

    button.addTarget(
        self,
        action: #selector(fsrTapped),
        for: .touchUpInside
    )

} else if [
    "Live Stock Viewer",
    "Stock Management",
    "Part Availability",
    "Part Requests"
].contains(text) {

    button.addTarget(
        self,
        action: #selector(inventoryTapped),
        for: .touchUpInside
    )

} else if text == "Manage Products" {

    button.addTarget(
        self,
        action: #selector(productsTapped),
        for: .touchUpInside
    )

} else {

    button.addTarget(
        self,
        action: #selector(genericMenuTapped(_:)),
        for: .touchUpInside
    )
}

        // Add button to dashboard
        stackView.addArrangedSubview(button)
    }

@objc private func leaveManagementTapped() {

    let leaveVC = LeaveManagementViewController()

    leaveVC.modalPresentationStyle = .fullScreen

    present(leaveVC, animated: true)
}

@objc private func productsTapped() {
    let productsVC = ProductListViewController()
    productsVC.modalPresentationStyle = .fullScreen
    present(productsVC, animated: true)
}

@objc private func inventoryTapped() {
    let inventoryVC = InventoryViewController()
    inventoryVC.modalPresentationStyle = .fullScreen
    present(inventoryVC, animated: true)
}


@objc private func fsrTapped() {
    let fsrVC = FSRViewController()
    fsrVC.modalPresentationStyle = .fullScreen
    present(fsrVC, animated: true)
}

    // MARK: - Attendance Navigation

    @objc private func attendanceTapped() {

        let attendanceVC = AttendanceViewController()

        attendanceVC.modalPresentationStyle = .fullScreen

        present(attendanceVC, animated: true)
    }

    // MARK: - Logout

    @objc private func logoutTapped() {

        AppSession.shared.signOut()

        let defaults = UserDefaults.standard

        [
            "USER_ROLE",
            "USER_NAME",
            "EMP_ID"
        ].forEach {
            defaults.removeObject(forKey: $0)
        }

        if let window = view.window {
            window.rootViewController = LoginViewController()
        }
    }

    // MARK: - Other Dashboard Modules

    @objc private func genericMenuTapped(
        _ sender: UIButton
    ) {

        let title = sender.title(
            for: .normal
        ) ?? "Screen"

        let alert = UIAlertController(
            title: title,
            message: "This native screen is currently under construction.",
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
