import UIKit

final class InventoryViewController: UIViewController {

    private let stockURL = URL(
        string: "https://yashswi.in/forms/public_stock_viewer.php"
    )!

    private let requestURL = URL(
        string: "https://yashswi.in/forms/part_request/part_request.php"
    )!
    private let historyURL = URL(
        string: "https://yashswi.in/forms/part_request/view_partrequest.php"
    )!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Inventory"

        let heading = UILabel()
        heading.text = "Inventory Management"
        heading.font = .boldSystemFont(ofSize: 27)
        heading.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Check spare parts availability and submit part requests."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stockButton = makeButton(
            "View Live Stock",
            action: #selector(openStock)
        )

        let requestButton = makeButton(
            "Request Spare Parts",
            action: #selector(openRequest)
        )

        let historyButton = makeButton(
            "My Part Requests",
            action: #selector(openHistory)
        )
        let backButton = makeButton(
            "Back",
            action: #selector(goBack)
        )

        let stack = UIStackView(arrangedSubviews: [
            heading,
            subtitle,
            stockButton,
            requestButton,
            historyButton,
            backButton
        ])

        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            stack.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            )
        ])
    }

    private func makeButton(
        _ text: String,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(
            equalToConstant: 54
        ).isActive = true

        button.addTarget(
            self,
            action: action,
            for: .touchUpInside
        )

        return button
    }

    @objc private func openStock() {
        openWebsite(stockURL)
    }

    @objc private func openRequest() {
        openWebsite(requestURL)
    }

    @objc private func openHistory() {
        openWebsite(historyURL)
    }
    private func openWebsite(_ url: URL) {
        guard AppSession.shared.authenticatedEmployeeId != nil else {
            showError("Please log in before accessing inventory.")
            return
        }

        let controller = YashswiWebViewController(
            dashboardURL: url
        )

        controller.modalPresentationStyle = .fullScreen

        present(controller, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Inventory",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }

    @objc private func goBack() {
        if let navigationController = navigationController,
           navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}